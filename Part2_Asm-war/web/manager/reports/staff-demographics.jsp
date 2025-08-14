<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.HashMap" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.Collections" %>
<%@ page import="java.util.Comparator" %>
<%@ page import="javax.naming.InitialContext" %>
<%@ page import="model.*" %>
<%@ page import="java.text.DecimalFormat" %>

<%
    // Check if manager is logged in
    Manager loggedInManager = (Manager) session.getAttribute("manager");
    if (loggedInManager == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    // Get EJB facades using JNDI lookup
    DoctorFacade doctorFacade = null;
    CounterStaffFacade counterStaffFacade = null;
    ManagerFacade managerFacade = null;

    try {
        InitialContext ctx = new InitialContext();
        doctorFacade = (DoctorFacade) ctx.lookup("java:global/Part2_Asm/Part2_Asm-ejb/DoctorFacade!model.DoctorFacade");
        counterStaffFacade = (CounterStaffFacade) ctx.lookup("java:global/Part2_Asm/Part2_Asm-ejb/CounterStaffFacade!model.CounterStaffFacade");
        managerFacade = (ManagerFacade) ctx.lookup("java:global/Part2_Asm/Part2_Asm-ejb/ManagerFacade!model.ManagerFacade");
    } catch (Exception e) {
        System.out.println("EJB lookup failed: " + e.getMessage());
    }

    // Initialize data structures
    List<Doctor> allDoctors = new ArrayList<Doctor>();
    List<CounterStaff> allCounterStaff = new ArrayList<CounterStaff>();
    List<Manager> allManagers = new ArrayList<Manager>(); // Commenting out for now

    int totalDoctors = 0;
    int totalCounterStaff = 0;
    int totalManagers = 1; // Assuming there's at least 1 manager (the logged-in one)
    int totalStaff = 0;

    // Gender counts
    int maleDoctors = 0, femaleDoctors = 0;
    int maleCounterStaff = 0, femaleCounterStaff = 0;
    int maleManagers = 0, femaleManagers = 0; // Default assuming current manager is male

    // Specialization counts
    Map<String, Integer> specializationCounts = new HashMap<String, Integer>();

    // Fetch real data from EJBs
    if (doctorFacade != null && counterStaffFacade != null) {
        try {
            // Get all doctors
            allDoctors = doctorFacade.findAll();
            totalDoctors = allDoctors.size();

            // Count doctor genders and specializations
            for (Doctor doctor : allDoctors) {
                if (doctor.getGender() != null) {
                    if ("Male".equalsIgnoreCase(doctor.getGender()) || "M".equalsIgnoreCase(doctor.getGender())) {
                        maleDoctors++;
                    } else if ("Female".equalsIgnoreCase(doctor.getGender()) || "F".equalsIgnoreCase(doctor.getGender())) {
                        femaleDoctors++;
                    }
                }

                // Count specializations
                String specialization = doctor.getSpecialization();
                if (specialization != null && !specialization.trim().isEmpty()) {
                    specializationCounts.put(specialization, specializationCounts.getOrDefault(specialization, 0) + 1);
                }
            }

            // Get all counter staff
            allCounterStaff = counterStaffFacade.findAll();
            totalCounterStaff = allCounterStaff.size();

            // Count counter staff genders
            for (CounterStaff staff : allCounterStaff) {
                if (staff.getGender() != null) {
                    if ("Male".equalsIgnoreCase(staff.getGender()) || "M".equalsIgnoreCase(staff.getGender())) {
                        maleCounterStaff++;
                    } else if ("Female".equalsIgnoreCase(staff.getGender()) || "F".equalsIgnoreCase(staff.getGender())) {
                        femaleCounterStaff++;
                    }
                }
            }

            // For managers, check if ManagerFacade is available
            if (managerFacade != null) {
                try {
                    allManagers = managerFacade.findAll();
                    totalManagers = allManagers.size();
                    
                    // Reset default values since we have real data
                    maleManagers = 0;
                    femaleManagers = 0;

                    // Count manager genders
                    for (Manager manager : allManagers) {
                        if (manager.getGender() != null) {
                            if ("Male".equalsIgnoreCase(manager.getGender()) || "M".equalsIgnoreCase(manager.getGender())) {
                                maleManagers++;
                            } else if ("Female".equalsIgnoreCase(manager.getGender()) || "F".equalsIgnoreCase(manager.getGender())) {
                                femaleManagers++;
                            }
                        }
                    }
                } catch (Exception e) {
                    System.out.println("Error fetching managers: " + e.getMessage());
                    // Keep default values: totalManagers = 1, maleManagers = 1, femaleManagers = 0
                }
            }

        } catch (Exception e) {
            System.out.println("Error fetching data from EJB: " + e.getMessage());
            e.printStackTrace();
        }
    }

    totalStaff = totalDoctors + totalCounterStaff + totalManagers;
    int totalMale = maleDoctors + maleCounterStaff + maleManagers;
    int totalFemale = femaleDoctors + femaleCounterStaff + femaleManagers;

    DecimalFormat df = new DecimalFormat("#.#");
%>

<!DOCTYPE html>
<html lang="en">
    <head>
        <title>Staff Demographics Report - APU Medical Center</title>
        <%@ include file="/includes/head.jsp" %>
        <link rel="stylesheet" href="<%= request.getContextPath()%>/css/manager-homepage.css">
        <link rel="stylesheet" href="<%= request.getContextPath()%>/css/manage-staff.css">
        <link rel="stylesheet" href="<%= request.getContextPath()%>/css/reports.css">
        <!-- Chart.js -->
        <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
        <!-- jsPDF -->
        <script src="https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js"></script>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/html2canvas/1.4.1/html2canvas.min.js"></script>
    </head>

    <body id="top" data-spy="scroll" data-target=".navbar-collapse" data-offset="50">
        <%@ include file="/includes/header.jsp" %>
        <%@ include file="/includes/navbar.jsp" %>

        <!-- PAGE HEADER -->
        <section class="page-header">
            <div class="container">
                <div class="row">
                    <div class="col-md-12">
                        <h1 class="wow fadeInUp">
                            <i class="fa fa-users" style="color:white"></i>
                            <span style="color:white">Staff Demographics Report</span>
                        </h1>
                        <p class="lead wow fadeInUp" data-wow-delay="0.2s" style="color: whitesmoke">
                            Gender distribution, age groups, and workforce analysis
                        </p>
                        <nav aria-label="breadcrumb" class="wow fadeInUp" data-wow-delay="0.3s">
                            <ol class="breadcrumb" style="background: transparent; margin: 0;">
                                <li class="breadcrumb-item">
                                    <a href="<%= request.getContextPath()%>/ManagerHomepageServlet" style="color: rgba(255,255,255,0.8);">Dashboard</a>
                                </li>
                                <li class="breadcrumb-item">
                                    <a href="<%= request.getContextPath()%>/manager/reports.jsp" style="color: rgba(255,255,255,0.8);">Reports</a>
                                </li>
                                <li class="breadcrumb-item active" style="color: white;">Staff Demographics</li>
                            </ol>
                        </nav>
                    </div>
                </div>
            </div>
        </section>

        <!-- REPORT CONTENT -->
        <section id="reportContent" class="analytics-dashboard" style="padding: 60px 0;">
            <div class="container">
                <!-- Action Buttons -->
                <div class="row" style="margin-bottom: 30px;">
                    <div class="col-md-12" style="display: flex; justify-content: space-between;">
                        <a href="<%= request.getContextPath()%>/manager/reports.jsp" class="btn btn-secondary">
                            <i class="fa fa-arrow-left"></i> Back to Reports
                        </a> 
                        <button class="btn btn-primary" onclick="downloadPDF()" style="margin-right: 10px;">
                            <i class="fa fa-download"></i> Download PDF
                        </button>
                    </div>
                </div>

                <!-- Summary KPIs -->
                <div class="row">
                    <div class="col-md-3 col-sm-6">
                        <div class="kpi-card">
                            <div class="kpi-icon" style="background: linear-gradient(45deg, #2c2577 0%, #f41212 100%);">
                                <i class="fa fa-users"></i>
                            </div>
                            <div class="kpi-content">
                                <h3 id="totalStaff">0</h3>
                                <p>Total Staff</p>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-3 col-sm-6">
                        <div class="kpi-card">
                            <div class="kpi-icon" style="background: linear-gradient(45deg, #f41212 0%, #2c2577 100%);">
                                <i class="fa fa-user-md"></i>
                            </div>
                            <div class="kpi-content">
                                <h3 id="totalDoctors">0</h3>
                                <p>Doctors</p>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-3 col-sm-6">
                        <div class="kpi-card">
                            <div class="kpi-icon" style="background: linear-gradient(45deg, #2c2577 0%, #f41212 100%);">
                                <i class="fa fa-user"></i>
                            </div>
                            <div class="kpi-content">
                                <h3 id="totalCounterStaff">0</h3>
                                <p>Counter Staff</p>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-3 col-sm-6">
                        <div class="kpi-card">
                            <div class="kpi-icon" style="background: linear-gradient(45deg, #f41212 0%, #2c2577 100%);">
                                <i class="fa fa-briefcase"></i>
                            </div>
                            <div class="kpi-content">
                                <h3 id="totalManagers">0</h3>
                                <p>Managers</p>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Charts Row -->
                <div class="row charts-row">
                    <!-- Gender Distribution -->
                    <div class="col-md-6">
                        <div class="chart-container">
                            <div class="chart-header">
                                <h3><i class="fa fa-pie-chart"></i> Gender Distribution</h3>
                            </div>
                            <div class="chart-body">
                                <canvas id="genderChart"></canvas>
                            </div>
                        </div>
                    </div>

                    <!-- Role Distribution -->
                    <div class="col-md-6">
                        <div class="chart-container">
                            <div class="chart-header">
                                <h3><i class="fa fa-bar-chart"></i> Role Distribution</h3>
                            </div>
                            <div class="chart-body">
                                <canvas id="roleChart"></canvas>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Second Charts Row -->
                <div class="row charts-row">
                    <!-- Specialization Distribution -->
                    <div class="col-md-12">
                        <div class="chart-container">
                            <div class="chart-header">
                                <h3><i class="fa fa-stethoscope"></i> Doctor Specializations</h3>
                            </div>
                            <div class="chart-body">
                                <canvas id="specializationChart"></canvas>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Detailed Tables -->
                <div class="row tables-row">
                    <!-- Demographics Summary Table -->
                    <div class="col-md-12">
                        <div class="table-container">
                            <div class="table-header">
                                <h3><i class="fa fa-table"></i> Demographics Summary</h3>
                            </div>
                            <div class="table-body">
                                <table class="table table-striped performance-table">
                                    <thead>
                                        <tr>
                                            <th>Category</th>
                                            <th>Male</th>
                                            <th>Female</th>
                                            <th>Total</th>
                                            <th>Male %</th>
                                            <th>Female %</th>
                                        </tr>
                                    </thead>
                                    <tbody id="demographicsTable">
                                        <!-- Data will be loaded via JavaScript -->
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </section>

        <%@ include file="/includes/footer.jsp" %>
        <%@ include file="/includes/scripts.jsp" %>

        <script>
            let genderChart, roleChart, specializationChart;

            $(document).ready(function () {
                loadStaffDemographicsData();
            });

            function loadStaffDemographicsData() {
                // Use real data from JSP/EJB instead of mock data
                const realData = {
                    totalStaff: <%= totalStaff%>,
                    totalDoctors: <%= totalDoctors%>,
                    totalCounterStaff: <%= totalCounterStaff%>,
                    totalManagers: <%= totalManagers%>,
                    genderDistribution: {
                        labels: ['Male', 'Female'],
                        data: [<%= totalMale%>, <%= totalFemale%>]
                    },
                    roleDistribution: {
                        labels: ['Doctors', 'Counter Staff', 'Managers'],
                        data: [<%= totalDoctors%>, <%= totalCounterStaff%>, <%= totalManagers%>]
                    },
                    specializationDistribution: {
                        labels: [
            <%
                                boolean first = true;
                                for (Map.Entry<String, Integer> entry : specializationCounts.entrySet()) {
                                    if (!first) {
                                        out.print(", ");
                                    }
                                    first = false;
                                    out.print("'" + entry.getKey().replace("'", "\\'") + "'");
                                }
            %>
                        ],
                        data: [
            <%
                                first = true;
                                for (Map.Entry<String, Integer> entry : specializationCounts.entrySet()) {
                                    if (!first) {
                                        out.print(", ");
                                    }
                                    first = false;
                                    out.print(entry.getValue());
                                }
            %>
                        ]
                    },
                    demographicsBreakdown: {
                        doctors: {male: <%= maleDoctors%>, female: <%= femaleDoctors%>},
                        counterStaff: {male: <%= maleCounterStaff%>, female: <%= femaleCounterStaff%>},
                        managers: {male: <%= maleManagers%>, female: <%= femaleManagers%>}
                    }
                };

                updateKPIs(realData);
                createCharts(realData);
                populateTables(realData);
            }

            function updateKPIs(data) {
                $('#totalStaff').text(data.totalStaff);
                $('#totalDoctors').text(data.totalDoctors);
                $('#totalCounterStaff').text(data.totalCounterStaff);
                $('#totalManagers').text(data.totalManagers);
            }

            function createCharts(data) {
                // Common chart options
                const commonOptions = {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: {
                            position: 'bottom'
                        }
                    }
                };

                // Gender Distribution Chart (Doughnut)
                const genderCtx = document.getElementById('genderChart').getContext('2d');
                genderChart = new Chart(genderCtx, {
                    type: 'doughnut',
                    data: {
                        labels: data.genderDistribution.labels,
                        datasets: [{
                                data: data.genderDistribution.data,
                                backgroundColor: [
                                    'rgba(44, 37, 119, 0.8)',
                                    'rgba(244, 18, 18, 0.8)'
                                ]
                            }]
                    },
                    options: commonOptions
                });

                // Role Distribution Chart (Bar)
                const roleCtx = document.getElementById('roleChart').getContext('2d');
                roleChart = new Chart(roleCtx, {
                    type: 'bar',
                    data: {
                        labels: data.roleDistribution.labels,
                        datasets: [{
                                label: 'Number of Staff',
                                data: data.roleDistribution.data,
                                backgroundColor: [
                                    'rgba(244, 18, 18, 0.8)',
                                    'rgba(44, 37, 119, 0.8)',
                                    'rgba(255, 193, 7, 0.8)'
                                ]
                            }]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        scales: {
                            y: {
                                beginAtZero: true,
                                grid: {
                                    color: 'rgba(0,0,0,0.1)'
                                }
                            },
                            x: {
                                grid: {
                                    display: false
                                }
                            }
                        }
                    }
                });

                // Specialization Distribution Chart (Polar Area)
                if (data.specializationDistribution.labels.length > 0) {
                    const specializationCtx = document.getElementById('specializationChart').getContext('2d');
                    specializationChart = new Chart(specializationCtx, {
                        type: 'polarArea',
                        data: {
                            labels: data.specializationDistribution.labels,
                            datasets: [{
                                    data: data.specializationDistribution.data,
                                    backgroundColor: [
                                        'rgba(244, 18, 18, 0.8)',
                                        'rgba(44, 37, 119, 0.8)',
                                        'rgba(255, 193, 7, 0.8)',
                                        'rgba(40, 167, 69, 0.8)',
                                        'rgba(108, 117, 125, 0.8)',
                                        'rgba(255, 99, 132, 0.8)',
                                        'rgba(255, 159, 64, 0.8)',
                                        'rgba(153, 102, 255, 0.8)'
                                    ]
                                }]
                        },
                        options: commonOptions
                    });
                } else {
                    // Display "No Data" message if no specializations
                    const ctx = document.getElementById('specializationChart').getContext('2d');
                    ctx.font = '16px Arial';
                    ctx.fillStyle = '#6c757d';
                    ctx.textAlign = 'center';
                    ctx.fillText('No specialization data available', ctx.canvas.width / 2, ctx.canvas.height / 2);
                }
            }

            function populateTables(data) {
                // Helper function to safely calculate percentages
                function calculatePercentage(part, total) {
                    if (total === 0 || isNaN(part) || isNaN(total))
                        return '0.0';
                    return ((part / total) * 100).toFixed(1);
                }

                // Extract values with fallback to 0
                const doctorMale = data.demographicsBreakdown.doctors.male || 0;
                const doctorFemale = data.demographicsBreakdown.doctors.female || 0;
                const staffMale = data.demographicsBreakdown.counterStaff.male || 0;
                const staffFemale = data.demographicsBreakdown.counterStaff.female || 0;
                const managerMale = data.demographicsBreakdown.managers.male || 0;
                const managerFemale = data.demographicsBreakdown.managers.female || 0;

                // Build table HTML using string concatenation for reliability
                let tableHtml = '';
                
                // Doctors row
                const doctorTotal = doctorMale + doctorFemale;
                tableHtml += '<tr>';
                tableHtml += '<td><strong>Doctors</strong></td>';
                tableHtml += '<td>' + doctorMale + '</td>';
                tableHtml += '<td>' + doctorFemale + '</td>';
                tableHtml += '<td>' + doctorTotal + '</td>';
                tableHtml += '<td>' + calculatePercentage(doctorMale, doctorTotal) + '%</td>';
                tableHtml += '<td>' + calculatePercentage(doctorFemale, doctorTotal) + '%</td>';
                tableHtml += '</tr>';
                
                // Counter Staff row
                const staffTotal = staffMale + staffFemale;
                tableHtml += '<tr>';
                tableHtml += '<td><strong>Counter Staff</strong></td>';
                tableHtml += '<td>' + staffMale + '</td>';
                tableHtml += '<td>' + staffFemale + '</td>';
                tableHtml += '<td>' + staffTotal + '</td>';
                tableHtml += '<td>' + calculatePercentage(staffMale, staffTotal) + '%</td>';
                tableHtml += '<td>' + calculatePercentage(staffFemale, staffTotal) + '%</td>';
                tableHtml += '</tr>';
                
                // Managers row
                const managerTotal = managerMale + managerFemale;
                tableHtml += '<tr>';
                tableHtml += '<td><strong>Managers</strong></td>';
                tableHtml += '<td>' + managerMale + '</td>';
                tableHtml += '<td>' + managerFemale + '</td>';
                tableHtml += '<td>' + managerTotal + '</td>';
                tableHtml += '<td>' + calculatePercentage(managerMale, managerTotal) + '%</td>';
                tableHtml += '<td>' + calculatePercentage(managerFemale, managerTotal) + '%</td>';
                tableHtml += '</tr>';
                
                // Total row
                const totalMale = doctorMale + staffMale + managerMale;
                const totalFemale = doctorFemale + staffFemale + managerFemale;
                const grandTotal = totalMale + totalFemale;
                tableHtml += '<tr style="background-color: #f8f9fa; font-weight: bold;">';
                tableHtml += '<td><strong>TOTAL</strong></td>';
                tableHtml += '<td>' + totalMale + '</td>';
                tableHtml += '<td>' + totalFemale + '</td>';
                tableHtml += '<td>' + grandTotal + '</td>';
                tableHtml += '<td>' + calculatePercentage(totalMale, grandTotal) + '%</td>';
                tableHtml += '<td>' + calculatePercentage(totalFemale, grandTotal) + '%</td>';
                tableHtml += '</tr>';

                $('#demographicsTable').html(tableHtml);
            }

            function downloadPDF() {
                // Check if jsPDF is loaded
                if (typeof window.jspdf === 'undefined') {
                    alert('PDF generation library is not loaded. Please try again.');
                    return;
                }

                const {jsPDF} = window.jspdf;
                const pdf = new jsPDF('p', 'mm', 'a4');
                const pageWidth = pdf.internal.pageSize.getWidth();
                const pageHeight = pdf.internal.pageSize.getHeight();

                // Show loading message
                var loadingDiv = document.createElement('div');
                loadingDiv.innerHTML = '<div style="position:fixed;top:50%;left:50%;transform:translate(-50%,-50%);background:white;padding:20px;border:2px solid #ccc;border-radius:10px;z-index:9999;"><i class="fa fa-spinner fa-spin"></i> Generating PDF...</div>';
                document.body.appendChild(loadingDiv);

                let currentY = 20;

                // Add title and header
                pdf.setFontSize(24);
                pdf.setTextColor(44, 37, 119);
                pdf.text('Staff Demographics Report', 20, currentY);
                currentY += 10;

                // Add subtitle
                pdf.setFontSize(12);
                pdf.setTextColor(100, 100, 100);
                pdf.text('APU Medical Center', 20, currentY);
                currentY += 8;
                pdf.text('Generated on: ' + new Date().toLocaleDateString(), 20, currentY);
                currentY += 15;

                // Add KPI summary section
                pdf.setFontSize(16);
                pdf.setTextColor(44, 37, 119);
                pdf.text('Demographics Summary', 20, currentY);
                currentY += 10;

                pdf.setFontSize(11);
                pdf.setTextColor(0, 0, 0);
                pdf.text('Total Staff: <%= totalStaff%>', 20, currentY);
                pdf.text('Doctors: <%= totalDoctors%>', 70, currentY);
                currentY += 7;
                pdf.text('Counter Staff: <%= totalCounterStaff%>', 20, currentY);
                pdf.text('Managers: <%= totalManagers%>', 70, currentY);
                currentY += 20;

                // Function to capture and add chart to PDF
                function addChartToPDF(chartId, title, callback) {
                    const canvas = document.getElementById(chartId);
                    if (!canvas) {
                        callback();
                        return;
                    }

                    html2canvas(canvas, {
                        scale: 2,
                        useCORS: true,
                        logging: false,
                        backgroundColor: '#ffffff'
                    }).then(function (chartCanvas) {
                        const chartImg = chartCanvas.toDataURL('image/png');
                        const imgWidth = 170;
                        const imgHeight = (chartCanvas.height * imgWidth) / chartCanvas.width;

                        // Check if we need a new page
                        if (currentY + imgHeight + 20 > pageHeight - 20) {
                            pdf.addPage();
                            currentY = 20;
                        }

                        // Add chart title
                        pdf.setFontSize(14);
                        pdf.setTextColor(44, 37, 119);
                        pdf.text(title, 20, currentY);
                        currentY += 10;

                        // Add chart image
                        pdf.addImage(chartImg, 'PNG', 20, currentY, imgWidth, imgHeight);
                        currentY += imgHeight + 15;

                        callback();
                    }).catch(function (error) {
                        console.error('Error capturing chart:', error);
                        callback();
                    });
                }

                // Sequential processing of charts and tables
                addChartToPDF('genderChart', 'Gender Distribution', function () {
                    addChartToPDF('roleChart', 'Role Distribution', function () {
                        addChartToPDF('specializationChart', 'Doctor Specializations', function () {
                            // Add a new page for tables
                            pdf.addPage();
                            currentY = 20;

                            // Add tables section header
                            pdf.setFontSize(18);
                            pdf.setTextColor(44, 37, 119);
                            pdf.text('Demographics Table', 20, currentY);
                            currentY += 15;

                            // Get the demographics table
                            const tableContainer = document.querySelector('.table-container');
                            if (tableContainer) {
                                html2canvas(tableContainer, {
                                    scale: 1.5,
                                    useCORS: true,
                                    logging: false,
                                    backgroundColor: '#ffffff'
                                }).then(function (tableCanvas) {
                                    const tableImg = tableCanvas.toDataURL('image/png');
                                    const imgWidth = 170;
                                    const imgHeight = (tableCanvas.height * imgWidth) / tableCanvas.width;

                                    // Add table image
                                    pdf.addImage(tableImg, 'PNG', 20, currentY, imgWidth, imgHeight);

                                    // Remove loading message and save PDF
                                    document.body.removeChild(loadingDiv);
                                    pdf.save('Staff_Demographics_Report_' + new Date().toISOString().split('T')[0] + '.pdf');
                                }).catch(function (error) {
                                    console.error('Error capturing table:', error);
                                    document.body.removeChild(loadingDiv);
                                    pdf.save('Staff_Demographics_Report_' + new Date().toISOString().split('T')[0] + '.pdf');
                                });
                            } else {
                                // If table not found, just finish without table
                                document.body.removeChild(loadingDiv);
                                pdf.save('Staff_Demographics_Report_' + new Date().toISOString().split('T')[0] + '.pdf');
                            }
                        });
                    });
                });
            }
        </script>
    </body>
</html>
