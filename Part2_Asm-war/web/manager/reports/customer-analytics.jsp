<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.HashMap" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="model.*" %>
<%@ page import="java.text.DecimalFormat" %>

<%
    // Check if manager is logged in
//    Manager loggedInManager = (Manager) session.getAttribute("manager");
//    if (loggedInManager == null) {
//        response.sendRedirect(request.getContextPath() + "/login.jsp");
//        return;
//    }
%>

<!DOCTYPE html>
<html lang="en">
    <head>
        <title>Customer Analytics Report - APU Medical Center</title>
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
                            <i class="fa fa-user-md" style="color:white"></i>
                            <span style="color:white">Customer Analytics Report</span>
                        </h1>
                        <p class="lead wow fadeInUp" data-wow-delay="0.2s" style="color: whitesmoke">
                            Patient demographics, peak hours, popular treatments, and visit patterns
                        </p>
                        <nav aria-label="breadcrumb" class="wow fadeInUp" data-wow-delay="0.3s">
                            <ol class="breadcrumb" style="background: transparent; margin: 0;">
                                <li class="breadcrumb-item">
                                    <a href="<%= request.getContextPath()%>/ManagerHomepageServlet" style="color: rgba(255,255,255,0.8);">Dashboard</a>
                                </li>
                                <li class="breadcrumb-item">
                                    <a href="<%= request.getContextPath()%>/manager/reports.jsp" style="color: rgba(255,255,255,0.8);">Reports</a>
                                </li>
                                <li class="breadcrumb-item active" style="color: white;">Customer Analytics</li>
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
                    <div class="row">
                        <div class="col-md-12" style="display: flex; justify-content: space-between;">
                            <a href="<%= request.getContextPath()%>/manager/reports.jsp" class="btn btn-secondary">
                                <i class="fa fa-arrow-left"></i> Back to Reports
                            </a> 
                            <button class="btn btn-primary" onclick="downloadPDF()" style="margin-right: 10px;">
                                <i class="fa fa-download"></i> Download PDF
                            </button>
                        </div>
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
                                <h3 id="totalCustomers">0</h3>
                                <p>Total Customers</p>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-3 col-sm-6">
                        <div class="kpi-card">
                            <div class="kpi-icon" style="background: linear-gradient(45deg, #f41212 0%, #2c2577 100%);">
                                <i class="fa fa-user-plus"></i>
                            </div>
                            <div class="kpi-content">
                                <h3 id="newCustomers">0</h3>
                                <p>New This Month</p>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-3 col-sm-6">
                        <div class="kpi-card">
                            <div class="kpi-icon" style="background: linear-gradient(45deg, #2c2577 0%, #f41212 100%);">
                                <i class="fa fa-clock-o"></i>
                            </div>
                            <div class="kpi-content">
                                <h3 id="peakHour">0</h3>
                                <p>Peak Hour</p>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-3 col-sm-6">
                        <div class="kpi-card">
                            <div class="kpi-icon" style="background: linear-gradient(45deg, #f41212 0%, #2c2577 100%);">
                                <i class="fa fa-star"></i>
                            </div>
                            <div class="kpi-content">
                                <h3 id="popularTreatment">--</h3>
                                <p>Most Popular</p>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Charts Row -->
                <div class="row charts-row">
                    <!-- Customer Age Distribution -->
                    <div class="col-md-6">
                        <div class="chart-container">
                            <div class="chart-header">
                                <h3><i class="fa fa-bar-chart"></i> Customer Age Distribution</h3>
                            </div>
                            <div class="chart-body">
                                <canvas id="ageDistributionChart"></canvas>
                            </div>
                        </div>
                    </div>

                    <!-- Peak Hours Analysis -->
                    <div class="col-md-6">
                        <div class="chart-container">
                            <div class="chart-header">
                                <h3><i class="fa fa-clock-o"></i> Peak Hours Analysis</h3>
                            </div>
                            <div class="chart-body">
                                <canvas id="peakHoursChart"></canvas>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Second Charts Row -->
                <div class="row charts-row">
                    <!-- Popular Treatments -->
                    <div class="col-md-6">
                        <div class="chart-container">
                            <div class="chart-header">
                                <h3><i class="fa fa-stethoscope"></i> Most Popular Treatments</h3>
                            </div>
                            <div class="chart-body">
                                <canvas id="popularTreatmentsChart"></canvas>
                            </div>
                        </div>
                    </div>

                    <!-- Visit Patterns -->
                    <div class="col-md-6">
                        <div class="chart-container">
                            <div class="chart-header">
                                <h3><i class="fa fa-pie-chart"></i> Customer Visit Patterns</h3>
                            </div>
                            <div class="chart-body">
                                <canvas id="visitPatternsChart"></canvas>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Third Charts Row -->
                <div class="row charts-row">
                    <!-- Customer Gender Distribution -->
                    <div class="col-md-6">
                        <div class="chart-container">
                            <div class="chart-header">
                                <h3><i class="fa fa-venus-mars"></i> Customer Gender Distribution</h3>
                            </div>
                            <div class="chart-body">
                                <canvas id="genderDistributionChart"></canvas>
                            </div>
                        </div>
                    </div>

                    <!-- Customer Growth Trend -->
                    <div class="col-md-6">
                        <div class="chart-container">
                            <div class="chart-header">
                                <h3><i class="fa fa-line-chart"></i> Customer Growth Trend</h3>
                            </div>
                            <div class="chart-body">
                                <canvas id="growthTrendChart"></canvas>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Detailed Tables -->
                <div class="row tables-row">
                    <!-- Customer Analytics Summary Table -->
                    <div class="col-md-12">
                        <div class="table-container">
                            <div class="table-header">
                                <h3><i class="fa fa-table"></i> Customer Analytics Summary</h3>
                            </div>
                            <div class="table-body">
                                <table class="table table-striped performance-table">
                                    <thead>
                                        <tr>
                                            <th>Age Group</th>
                                            <th>Total Customers</th>
                                            <th>Male</th>
                                            <th>Female</th>
                                            <th>Avg Visits</th>
                                            <th>Most Popular Treatment</th>
                                            <th>Preferred Time</th>
                                        </tr>
                                    </thead>
                                    <tbody id="customerAnalyticsTable">
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
            let ageDistributionChart, peakHoursChart, popularTreatmentsChart, visitPatternsChart, genderDistributionChart, growthTrendChart;

            $(document).ready(function () {
                loadCustomerAnalyticsData();
            });

            function loadCustomerAnalyticsData() {
                // Mock data for demonstration - replace with AJAX call to your servlet
                const mockData = {
                    totalCustomers: 780,
                    newCustomers: 45,
                    peakHour: '11-12 PM',
                    popularTreatment: 'General',
                    ageDistribution: {
                        labels: ['18-25', '26-35', '36-45', '46-55', '56+'],
                        data: [145, 298, 187, 98, 52]
                    },
                    peakHours: {
                        labels: ['9-10', '10-11', '11-12', '12-13', '13-14', '14-15', '15-16', '16-17'],
                        data: [28, 42, 65, 58, 35, 48, 52, 38]
                    },
                    popularTreatments: {
                        labels: ['General Consultation', 'Health Screening', 'Cardiology', 'Dermatology', 'Physiotherapy'],
                        data: [892, 234, 187, 156, 143]
                    },
                    visitPatterns: {
                        labels: ['First-time', '2-3 visits/year', '4-6 visits/year', '7+ visits/year'],
                        data: [284, 312, 128, 56]
                    },
                    genderDistribution: {
                        labels: ['Female', 'Male'],
                        data: [456, 324]
                    },
                    growthTrend: {
                        labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul'],
                        data: [650, 668, 695, 720, 745, 760, 780]
                    },
                    analyticsBreakdown: [
                        {ageGroup: '18-25', total: 145, male: 68, female: 77, avgVisits: 2.3, popularTreatment: 'General', preferredTime: '14-16'},
                        {ageGroup: '26-35', total: 298, male: 142, female: 156, avgVisits: 3.1, popularTreatment: 'Health Screening', preferredTime: '11-13'},
                        {ageGroup: '36-45', total: 187, male: 89, female: 98, avgVisits: 2.8, popularTreatment: 'Cardiology', preferredTime: '09-11'},
                        {ageGroup: '46-55', total: 98, male: 45, female: 53, avgVisits: 4.2, popularTreatment: 'General', preferredTime: '10-12'},
                        {ageGroup: '56+', total: 52, male: 28, female: 24, avgVisits: 5.1, popularTreatment: 'Cardiology', preferredTime: '09-11'}
                    ]
                };

                updateKPIs(mockData);
                createCharts(mockData);
                populateTables(mockData);
            }

            function updateKPIs(data) {
                $('#totalCustomers').text(data.totalCustomers);
                $('#newCustomers').text(data.newCustomers);
                $('#peakHour').text(data.peakHour);
                $('#popularTreatment').text(data.popularTreatment);
            }

            function createCharts(data) {
                // Age Distribution Chart
                const ageCtx = document.getElementById('ageDistributionChart').getContext('2d');
                ageDistributionChart = new Chart(ageCtx, {
                    type: 'bar',
                    data: {
                        labels: data.ageDistribution.labels,
                        datasets: [{
                            label: 'Number of Customers',
                            data: data.ageDistribution.data,
                            backgroundColor: 'rgba(244, 18, 18, 0.8)',
                            borderColor: 'rgba(244, 18, 18, 1)',
                            borderWidth: 1
                        }]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false
                    }
                });

                // Peak Hours Chart
                const peakCtx = document.getElementById('peakHoursChart').getContext('2d');
                peakHoursChart = new Chart(peakCtx, {
                    type: 'line',
                    data: {
                        labels: data.peakHours.labels,
                        datasets: [{
                            label: 'Appointments',
                            data: data.peakHours.data,
                            borderColor: 'rgba(44, 37, 119, 1)',
                            backgroundColor: 'rgba(44, 37, 119, 0.1)',
                            fill: true,
                            tension: 0.4
                        }]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false
                    }
                });

                // Popular Treatments Chart
                const treatmentsCtx = document.getElementById('popularTreatmentsChart').getContext('2d');
                popularTreatmentsChart = new Chart(treatmentsCtx, {
                    type: 'bar',
                    data: {
                        labels: data.popularTreatments.labels,
                        datasets: [{
                            label: 'Monthly Visits',
                            data: data.popularTreatments.data,
                            backgroundColor: 'rgba(44, 37, 119, 0.8)',
                            borderColor: 'rgba(44, 37, 119, 1)',
                            borderWidth: 1
                        }]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        indexAxis: 'y'
                    }
                });

                // Visit Patterns Chart
                const visitCtx = document.getElementById('visitPatternsChart').getContext('2d');
                visitPatternsChart = new Chart(visitCtx, {
                    type: 'doughnut',
                    data: {
                        labels: data.visitPatterns.labels,
                        datasets: [{
                            data: data.visitPatterns.data,
                            backgroundColor: [
                                'rgba(244, 18, 18, 0.8)',
                                'rgba(44, 37, 119, 0.8)',
                                'rgba(255, 193, 7, 0.8)',
                                'rgba(40, 167, 69, 0.8)'
                            ]
                        }]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        plugins: {
                            legend: {
                                position: 'bottom'
                            }
                        }
                    }
                });

                // Gender Distribution Chart
                const genderCtx = document.getElementById('genderDistributionChart').getContext('2d');
                genderDistributionChart = new Chart(genderCtx, {
                    type: 'pie',
                    data: {
                        labels: data.genderDistribution.labels,
                        datasets: [{
                            data: data.genderDistribution.data,
                            backgroundColor: [
                                'rgba(244, 18, 18, 0.8)',
                                'rgba(44, 37, 119, 0.8)'
                            ]
                        }]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        plugins: {
                            legend: {
                                position: 'bottom'
                            }
                        }
                    }
                });

                // Growth Trend Chart
                const growthCtx = document.getElementById('growthTrendChart').getContext('2d');
                growthTrendChart = new Chart(growthCtx, {
                    type: 'line',
                    data: {
                        labels: data.growthTrend.labels,
                        datasets: [{
                            label: 'Total Customers',
                            data: data.growthTrend.data,
                            borderColor: 'rgba(40, 167, 69, 1)',
                            backgroundColor: 'rgba(40, 167, 69, 0.1)',
                            fill: true,
                            tension: 0.4
                        }]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false
                    }
                });
            }

            function populateTables(data) {
                let tableHtml = '';
                data.analyticsBreakdown.forEach((row) => {
                    tableHtml += `
                        <tr>
                            <td>${row.ageGroup}</td>
                            <td>${row.total}</td>
                            <td>${row.male}</td>
                            <td>${row.female}</td>
                            <td>${row.avgVisits}</td>
                            <td>${row.popularTreatment}</td>
                            <td>${row.preferredTime}</td>
                        </tr>
                    `;
                });
                $('#customerAnalyticsTable').html(tableHtml);
            }

            function downloadPDF() {
                const { jsPDF } = window.jspdf;
                const pdf = new jsPDF('p', 'mm', 'a4');
                
                // Add title
                pdf.setFontSize(20);
                pdf.text('Customer Analytics Report', 20, 30);
                
                // Add date
                pdf.setFontSize(12);
                pdf.text('Generated on: ' + new Date().toLocaleDateString(), 20, 45);
                
                // Capture the content
                html2canvas(document.getElementById('reportContent')).then(canvas => {
                    const imgData = canvas.toDataURL('image/png');
                    const imgWidth = 170;
                    const pageHeight = 295;
                    const imgHeight = (canvas.height * imgWidth) / canvas.width;
                    let heightLeft = imgHeight;
                    
                    let position = 60;
                    
                    pdf.addImage(imgData, 'PNG', 20, position, imgWidth, imgHeight);
                    heightLeft -= pageHeight;
                    
                    while (heightLeft >= 0) {
                        position = heightLeft - imgHeight;
                        pdf.addPage();
                        pdf.addImage(imgData, 'PNG', 20, position, imgWidth, imgHeight);
                        heightLeft -= pageHeight;
                    }
                    
                    pdf.save('Customer_Analytics_Report.pdf');
                });
            }
        </script>
    </body>
</html>
