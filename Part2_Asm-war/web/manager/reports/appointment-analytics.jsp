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
<%@ page import="java.util.Calendar" %>
<%@ page import="java.text.SimpleDateFormat" %>

<%
    // Check if manager is logged in
    Manager loggedInManager = (Manager) session.getAttribute("manager");
    if (loggedInManager == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    // Get EJB facades using JNDI lookup
    AppointmentFacade appointmentFacade = null;
    DoctorFacade doctorFacade = null;

    try {
        InitialContext ctx = new InitialContext();
        appointmentFacade = (AppointmentFacade) ctx.lookup("java:global/Part2_Asm/Part2_Asm-ejb/AppointmentFacade!model.AppointmentFacade");
        doctorFacade = (DoctorFacade) ctx.lookup("java:global/Part2_Asm/Part2_Asm-ejb/DoctorFacade!model.DoctorFacade");
    } catch (Exception e) {
        System.out.println("EJB lookup failed: " + e.getMessage());
    }

    // Initialize data structures
    List<Appointment> allAppointments = new ArrayList<Appointment>();
    List<Doctor> allDoctors = new ArrayList<Doctor>();
    
    int totalAppointments = 0;
    int completedAppointments = 0;
    int pendingAppointments = 0;
    int cancelledAppointments = 0;
    int overdueAppointments = 0;
    
    // Weekly appointment counts (Mon-Sun)
    int[] weeklyAppointments = new int[7];
    
    // Monthly appointment counts (last 6 months)
    int[] monthlyAppointments = new int[6];
    String[] monthNames = new String[6];
    
    // Doctor booking statistics
    final Map<Integer, Integer> doctorBookingCounts = new HashMap<Integer, Integer>();
    final Map<Integer, Integer> doctorCompletedCounts = new HashMap<Integer, Integer>();
    final Map<Integer, Integer> doctorCancelledCounts = new HashMap<Integer, Integer>();

    // Fetch real data from EJBs
    if (appointmentFacade != null && doctorFacade != null) {
        try {
            // Get all appointments
            allAppointments = appointmentFacade.findAll();
            totalAppointments = allAppointments.size();
            
            // Get all doctors
            allDoctors = doctorFacade.findAll();
            
            // Initialize doctor counters
            for (Doctor doctor : allDoctors) {
                doctorBookingCounts.put(doctor.getId(), 0);
                doctorCompletedCounts.put(doctor.getId(), 0);
                doctorCancelledCounts.put(doctor.getId(), 0);
            }
            
            // Process appointments for statistics
            Calendar cal = Calendar.getInstance();
            SimpleDateFormat monthFormat = new SimpleDateFormat("MMM");
            
            // Initialize month names (last 6 months)
            for (int i = 5; i >= 0; i--) {
                cal.add(Calendar.MONTH, -i);
                monthNames[5-i] = monthFormat.format(cal.getTime());
                if (i > 0) cal.add(Calendar.MONTH, i); // Reset for next iteration
            }
            
            // Debug: Print month names
            System.out.println("[DEBUG] Month Names for Monthly Trends:");
            for (int i = 0; i < monthNames.length; i++) {
                System.out.println("[DEBUG] monthNames[" + i + "]: " + monthNames[i]);
            }

            for (Appointment appointment : allAppointments) {
                // Count by status
                String status = appointment.getStatus();
                if (status != null) {
                    if ("Completed".equalsIgnoreCase(status) || "Complete".equalsIgnoreCase(status)) {
                        completedAppointments++;
                    } else if ("Pending".equalsIgnoreCase(status) || "Scheduled".equalsIgnoreCase(status)) {
                        pendingAppointments++;
                    } else if ("Cancelled".equalsIgnoreCase(status) || "Cancel".equalsIgnoreCase(status)) {
                        cancelledAppointments++;
                    } else if ("Overdue".equalsIgnoreCase(status) || "Overdue".equalsIgnoreCase(status)) {
                        overdueAppointments++;
                    }
                }
                
                // Count by doctor
                if (appointment.getDoctor() != null) {
                    Integer doctorId = appointment.getDoctor().getId();
                    doctorBookingCounts.put(doctorId, doctorBookingCounts.getOrDefault(doctorId, 0) + 1);
                    
                    if ("Completed".equalsIgnoreCase(status) || "Complete".equalsIgnoreCase(status)) {
                        doctorCompletedCounts.put(doctorId, doctorCompletedCounts.getOrDefault(doctorId, 0) + 1);
                    } else if ("Cancelled".equalsIgnoreCase(status) || "Cancel".equalsIgnoreCase(status)) {
                        doctorCancelledCounts.put(doctorId, doctorCancelledCounts.getOrDefault(doctorId, 0) + 1);
                    }
                }
                
                // Count by day of week and month (parse actual dates)
                try {
                    if (appointment.getAppointmentDate() != null) {
                        // Parse the appointment date to determine correct month and day
                        Calendar appointmentCal = Calendar.getInstance();
                        
                        // Handle different date formats
                        if (appointment.getAppointmentDate() instanceof java.util.Date) {
                            appointmentCal.setTime((java.util.Date) appointment.getAppointmentDate());
                        } else {
                            // If it's a string, try to parse it
                            String dateStr = appointment.getAppointmentDate().toString();
                            if (dateStr.contains("-")) {
                                // Format: yyyy-mm-dd or yyyy-mm-dd hh:mm:ss.sss
                                String[] dateParts = dateStr.split(" ")[0].split("-"); // Get just the date part
                                int year = Integer.parseInt(dateParts[0]);
                                int month = Integer.parseInt(dateParts[1]) - 1; // Calendar months are 0-based
                                int day = Integer.parseInt(dateParts[2]);
                                appointmentCal.set(year, month, day);
                            }
                        }
                        
                        // Count by day of week (0 = Sunday, 1 = Monday, etc.)
                        int dayOfWeek = appointmentCal.get(Calendar.DAY_OF_WEEK) - 2; // Convert to 0=Monday
                        if (dayOfWeek < 0) dayOfWeek = 6; // Sunday becomes 6
                        weeklyAppointments[dayOfWeek]++;
                        
                        // Count by month - find which of our 6 months this appointment falls into
                        Calendar currentCal = Calendar.getInstance();
                        int monthIndex = -1;
                        
                        // Check each of our 6 months to see if this appointment falls in that month
                        for (int i = 0; i < 6; i++) {
                            Calendar checkCal = Calendar.getInstance();
                            checkCal.add(Calendar.MONTH, -(5-i)); // Go back (5-i) months from current
                            
                            if (appointmentCal.get(Calendar.YEAR) == checkCal.get(Calendar.YEAR) &&
                                appointmentCal.get(Calendar.MONTH) == checkCal.get(Calendar.MONTH)) {
                                monthIndex = i;
                                break;
                            }
                        }
                        
                        if (monthIndex >= 0) {
                            monthlyAppointments[monthIndex]++;
                            // Debug: Print each appointment's date and which month index it is counted towards
                            System.out.println("[DEBUG] Appointment ID: " + appointment.getId() + ", Date: " + appointment.getAppointmentDate() + ", Counted in monthIndex: " + monthIndex + " (" + monthNames[monthIndex] + ")");
                        } else {
                            // Appointment doesn't fall in our 6-month window
                            System.out.println("[DEBUG] Appointment ID: " + appointment.getId() + ", Date: " + appointment.getAppointmentDate() + ", NOT counted (outside 6-month window)");
                        }
                    }
                } catch (Exception e) {
                    // Handle date parsing errors
                    System.out.println("[DEBUG] Error parsing date for appointment: " + e.getMessage());
                }
            }
            // Debug: Print monthly appointment counts
            System.out.println("[DEBUG] Monthly Appointment Counts:");
            for (int i = 0; i < monthlyAppointments.length; i++) {
                System.out.println("[DEBUG] monthlyAppointments[" + i + "] (" + monthNames[i] + "): " + monthlyAppointments[i]);
            }
            
        } catch (Exception e) {
            System.out.println("Error fetching appointment data: " + e.getMessage());
            e.printStackTrace();
        }
    }

    DecimalFormat df = new DecimalFormat("#.#");
%>

<!DOCTYPE html>
<html lang="en">
    <head>
        <title>Appointment Analytics Report - APU Medical Center</title>
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
                            <i class="fa fa-calendar" style="color:white"></i>
                            <span style="color:white">Appointment Analytics Report</span>
                        </h1>
                        <p class="lead wow fadeInUp" data-wow-delay="0.2s" style="color: whitesmoke">
                            Booking trends, popular doctors, and appointment statistics
                        </p>
                        <nav aria-label="breadcrumb" class="wow fadeInUp" data-wow-delay="0.3s">
                            <ol class="breadcrumb" style="background: transparent; margin: 0;">
                                <li class="breadcrumb-item">
                                    <a href="<%= request.getContextPath()%>/ManagerHomepageServlet" style="color: rgba(255,255,255,0.8);">Dashboard</a>
                                </li>
                                <li class="breadcrumb-item">
                                    <a href="<%= request.getContextPath()%>/manager/reports.jsp" style="color: rgba(255,255,255,0.8);">Reports</a>
                                </li>
                                <li class="breadcrumb-item active" style="color: white;">Appointment Analytics</li>
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
                                <i class="fa fa-calendar"></i>
                            </div>
                            <div class="kpi-content">
                                <h3 id="totalAppointments">0</h3>
                                <p>Total Appointments</p>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-3 col-sm-6">
                        <div class="kpi-card">
                            <div class="kpi-icon" style="background: linear-gradient(45deg, #f41212 0%, #2c2577 100%);">
                                <i class="fa fa-check-circle"></i>
                            </div>
                            <div class="kpi-content">
                                <h3 id="completedAppointments">0</h3>
                                <p>Completed</p>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-3 col-sm-6">
                        <div class="kpi-card">
                            <div class="kpi-icon" style="background: linear-gradient(45deg, #2c2577 0%, #f41212 100%);">
                                <i class="fa fa-clock-o"></i>
                            </div>
                            <div class="kpi-content">
                                <h3 id="pendingAppointments">0</h3>
                                <p>Pending</p>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-3 col-sm-6">
                        <div class="kpi-card">
                            <div class="kpi-icon" style="background: linear-gradient(45deg, #f41212 0%, #2c2577 100%);">
                                <i class="fa fa-times-circle"></i>
                            </div>
                            <div class="kpi-content">
                                <h3 id="cancelledAppointments">0</h3>
                                <p>Cancelled</p>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Charts Row -->
                <div class="row charts-row">
                    <!-- Weekly Trends Chart -->
                    <div class="col-md-6">
                        <div class="chart-container">
                            <div class="chart-header">
                                <h3><i class="fa fa-line-chart"></i> Weekly Appointment Trends</h3>
                            </div>
                            <div class="chart-body">
                                <canvas id="weeklyTrendsChart"></canvas>
                            </div>
                        </div>
                    </div>

                    <!-- Appointment Status Distribution -->
                    <div class="col-md-6">
                        <div class="chart-container">
                            <div class="chart-header">
                                <h3><i class="fa fa-pie-chart"></i> Appointment Status Distribution</h3>
                            </div>
                            <div class="chart-body">
                                <canvas id="statusChart"></canvas>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Second Charts Row -->
                <div class="row charts-row">
                    <!-- Most Booked Doctors -->
                    <div class="col-md-6">
                        <div class="chart-container">
                            <div class="chart-header">
                                <h3><i class="fa fa-star"></i> Most Booked Doctors</h3>
                            </div>
                            <div class="chart-body">
                                <canvas id="mostBookedChart"></canvas>
                            </div>
                        </div>
                    </div>

                    <!-- Monthly Trends -->
                    <div class="col-md-6">
                        <div class="chart-container">
                            <div class="chart-header">
                                <h3><i class="fa fa-bar-chart"></i> Monthly Appointment Trends</h3>
                            </div>
                            <div class="chart-body">
                                <canvas id="monthlyTrendsChart"></canvas>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Detailed Tables -->
                <div class="row tables-row">
                    <!-- Most Booked Doctors Table -->
                    <div class="col-md-12">
                        <div class="table-container">
                            <div class="table-header">
                                <h3><i class="fa fa-trophy"></i> Most Booked Doctors Details</h3>
                            </div>
                            <div class="table-body">
                                <table class="table table-striped performance-table">
                                    <thead>
                                        <tr>
                                            <th>Rank</th>
                                            <th>Doctor Name</th>
                                            <th>Specialization</th>
                                            <th>Total Bookings</th>
                                            <th>Completed</th>
                                            <th>Cancelled</th>
                                            <th>Rating</th>
                                        </tr>
                                    </thead>
                                    <tbody id="mostBookedTable">
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
            let weeklyTrendsChart, statusChart, mostBookedChart, monthlyTrendsChart;

            $(document).ready(function () {
                loadAppointmentAnalyticsData();
            });

            function loadAppointmentAnalyticsData() {
                // Use real data from JSP/EJB instead of mock data
                const realData = {
                    totalAppointments: <%= totalAppointments %>,
                    completedAppointments: <%= completedAppointments %>,
                    pendingAppointments: <%= pendingAppointments %>,
                    cancelledAppointments: <%= cancelledAppointments %>,
                    weeklyTrends: {
                        labels: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'],
                        data: [<%= weeklyAppointments[0] %>, <%= weeklyAppointments[1] %>, <%= weeklyAppointments[2] %>, <%= weeklyAppointments[3] %>, <%= weeklyAppointments[4] %>, <%= weeklyAppointments[5] %>, <%= weeklyAppointments[6] %>]
                    },
                    statusDistribution: {
                        labels: ['Completed', 'Pending', 'Cancelled', 'Overdue'],
                        data: [<%= completedAppointments %>, <%= pendingAppointments %>, <%= cancelledAppointments %>, <%= overdueAppointments %>]
                    },
                    mostBookedDoctors: [
            <%
                        // Create a list of doctors sorted by rating (highest first)
                        List<Doctor> sortedDoctors = new ArrayList<Doctor>();
                        for (Doctor doctor : allDoctors) {
                            // Only include doctors who have bookings and a valid rating
                            if (doctorBookingCounts.get(doctor.getId()) > 0) {
                                sortedDoctors.add(doctor);
                            }
                        }
                        
                        // Sort by rating first (descending), then by booking count (descending) as tiebreaker
                        Collections.sort(sortedDoctors, new Comparator<Doctor>() {
                            public int compare(Doctor d1, Doctor d2) {
                                // Get ratings, default to 0.0 if null
                                Double rating1 = d1.getRating() != null ? d1.getRating() : 0.0;
                                Double rating2 = d2.getRating() != null ? d2.getRating() : 0.0;
                                
                                // First compare by rating (descending)
                                int ratingCompare = rating2.compareTo(rating1);
                                if (ratingCompare != 0) {
                                    return ratingCompare;
                                }
                                
                                // If ratings are equal, compare by booking count (descending)
                                Integer count1 = doctorBookingCounts.get(d1.getId());
                                Integer count2 = doctorBookingCounts.get(d2.getId());
                                return count2.compareTo(count1);
                            }
                        });
                        
                        // Output top 5 doctors
                        for (int i = 0; i < Math.min(5, sortedDoctors.size()); i++) {
                            Doctor doctor = sortedDoctors.get(i);
                            int bookings = doctorBookingCounts.get(doctor.getId());
                            int completed = doctorCompletedCounts.get(doctor.getId());
                            int cancelled = doctorCancelledCounts.get(doctor.getId());
                            
                            // Use actual rating from database
                            double rating = doctor.getRating() != null ? doctor.getRating() : 0.0;
                            
                            if (i > 0) out.print(",");
            %>
                        {
                            name: '<%= "Dr. " + doctor.getName().replace("'", "\\'") %>',
                            specialization: '<%= doctor.getSpecialization() != null ? doctor.getSpecialization().replace("'", "\\'") : "General" %>',
                            bookings: <%= bookings %>,
                            completed: <%= completed %>,
                            cancelled: <%= cancelled %>,
                            rating: <%= df.format(rating) %>
                        }
            <%
                        }
            %>
                    ],
                    monthlyTrends: {
                        labels: [
            <%
                        for (int i = 0; i < monthNames.length; i++) {
                            if (i > 0) out.print(", ");
                            out.print("'" + monthNames[i] + "'");
                        }
            %>
                        ],
                        data: [<%= monthlyAppointments[0] %>, <%= monthlyAppointments[1] %>, <%= monthlyAppointments[2] %>, <%= monthlyAppointments[3] %>, <%= monthlyAppointments[4] %>, <%= monthlyAppointments[5] %>]
                    }
                };

                updateKPIs(realData);
                createCharts(realData);
                populateTables(realData);
            }

            function updateKPIs(data) {
                $('#totalAppointments').text(data.totalAppointments);
                $('#completedAppointments').text(data.completedAppointments);
                $('#pendingAppointments').text(data.pendingAppointments);
                $('#cancelledAppointments').text(data.cancelledAppointments);
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

                // Weekly Trends Chart (Line)
                const weeklyCtx = document.getElementById('weeklyTrendsChart').getContext('2d');
                weeklyTrendsChart = new Chart(weeklyCtx, {
                    type: 'line',
                    data: {
                        labels: data.weeklyTrends.labels,
                        datasets: [{
                            label: 'Appointments',
                            data: data.weeklyTrends.data,
                            borderColor: 'rgba(244, 18, 18, 1)',
                            backgroundColor: 'rgba(244, 18, 18, 0.1)',
                            fill: true,
                            tension: 0.4
                        }]
                    },
                    options: commonOptions
                });

                // Status Distribution Chart (Doughnut)
                const statusCtx = document.getElementById('statusChart').getContext('2d');
                statusChart = new Chart(statusCtx, {
                    type: 'doughnut',
                    data: {
                        labels: data.statusDistribution.labels,
                        datasets: [{
                            data: data.statusDistribution.data,
                            backgroundColor: [
                                'rgba(40, 167, 69, 0.8)',
                                'rgba(255, 193, 7, 0.8)',
                                'rgba(220, 53, 69, 0.8)',
                                'rgba(253, 126, 20, 0.8)'
                            ]
                        }]
                    },
                    options: commonOptions
                });

                // Most Booked Doctors Chart (Horizontal Bar)
                const mostBookedCtx = document.getElementById('mostBookedChart').getContext('2d');
                mostBookedChart = new Chart(mostBookedCtx, {
                    type: 'bar',
                    data: {
                        labels: data.mostBookedDoctors.map(d => d.name.replace('Dr. ', '')),
                        datasets: [{
                            label: 'Total Bookings',
                            data: data.mostBookedDoctors.map(d => d.bookings),
                            backgroundColor: 'rgba(44, 37, 119, 0.8)',
                            borderColor: 'rgba(44, 37, 119, 1)',
                            borderWidth: 1
                        }]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        indexAxis: 'y',
                        scales: {
                            x: {
                                beginAtZero: true
                            }
                        }
                    }
                });

                // Monthly Trends Chart (Bar + Line combination)
                const monthlyCtx = document.getElementById('monthlyTrendsChart').getContext('2d');
                monthlyTrendsChart = new Chart(monthlyCtx, {
                    type: 'bar',
                    data: {
                        labels: data.monthlyTrends.labels,
                        datasets: [{
                            label: 'Monthly Appointments',
                            type: 'bar',
                            data: data.monthlyTrends.data,
                            backgroundColor: 'rgba(244, 18, 18, 0.6)',
                            borderColor: 'rgba(244, 18, 18, 1)',
                            borderWidth: 1,
                            yAxisID: 'y'
                        }, {
                            label: 'Trend Line',
                            type: 'line',
                            data: data.monthlyTrends.data,
                            borderColor: 'rgba(44, 37, 119, 1)',
                            backgroundColor: 'rgba(44, 37, 119, 0.1)',
                            borderWidth: 3,
                            fill: false,
                            tension: 0.4,
                            pointBackgroundColor: 'rgba(44, 37, 119, 1)',
                            pointBorderColor: '#ffffff',
                            pointBorderWidth: 2,
                            pointRadius: 6,
                            pointHoverRadius: 8,
                            yAxisID: 'y'
                        }]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        interaction: {
                            mode: 'index',
                            intersect: false,
                        },
                        plugins: {
                            legend: {
                                position: 'bottom'
                            },
                            tooltip: {
                                mode: 'index',
                                intersect: false,
                            }
                        },
                        scales: {
                            y: {
                                beginAtZero: true,
                                position: 'left',
                                title: {
                                    display: true,
                                    text: 'Number of Appointments'
                                }
                            }
                        }
                    }
                });
            }

            function populateTables(data) {
                let tableHtml = '';
                
                if (data.mostBookedDoctors && data.mostBookedDoctors.length > 0) {
                    data.mostBookedDoctors.forEach((doctor, index) => {
                        tableHtml += '<tr>';
                        tableHtml += '<td>' + (index + 1) + '</td>';
                        tableHtml += '<td>' + doctor.name + '</td>';
                        tableHtml += '<td>' + doctor.specialization + '</td>';
                        tableHtml += '<td>' + doctor.bookings + '</td>';
                        tableHtml += '<td>' + doctor.completed + '</td>';
                        tableHtml += '<td>' + doctor.cancelled + '</td>';
                        tableHtml += '<td><span class="rating-badge">' + doctor.rating + '/10</span></td>';
                        tableHtml += '</tr>';
                    });
                } else {
                    tableHtml = '<tr><td colspan="7" class="text-center text-muted">No booking data available</td></tr>';
                }
                
                $('#mostBookedTable').html(tableHtml);
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
                pdf.text('Appointment Analytics Report', 20, currentY);
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
                pdf.text('Appointment Summary', 20, currentY);
                currentY += 10;

                pdf.setFontSize(11);
                pdf.setTextColor(0, 0, 0);
                pdf.text('Total Appointments: <%= totalAppointments %>', 20, currentY);
                pdf.text('Completed: <%= completedAppointments %>', 70, currentY);
                currentY += 7;
                pdf.text('Pending: <%= pendingAppointments %>', 20, currentY);
                pdf.text('Cancelled: <%= cancelledAppointments %>', 70, currentY);
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
                addChartToPDF('weeklyTrendsChart', 'Weekly Appointment Trends', function () {
                    addChartToPDF('statusChart', 'Appointment Status Distribution', function () {
                        addChartToPDF('mostBookedChart', 'Most Booked Doctors', function () {
                            addChartToPDF('monthlyTrendsChart', 'Monthly Appointment Trends', function () {
                                // Add a new page for tables
                                pdf.addPage();
                                currentY = 20;

                                // Add tables section header
                                pdf.setFontSize(18);
                                pdf.setTextColor(44, 37, 119);
                                pdf.text('Most Booked Doctors Details', 20, currentY);
                                currentY += 15;

                                // Get the table
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
                                        pdf.save('Appointment_Analytics_Report_' + new Date().toISOString().split('T')[0] + '.pdf');
                                    }).catch(function (error) {
                                        console.error('Error capturing table:', error);
                                        document.body.removeChild(loadingDiv);
                                        pdf.save('Appointment_Analytics_Report_' + new Date().toISOString().split('T')[0] + '.pdf');
                                    });
                                } else {
                                    // If table not found, just finish without table
                                    document.body.removeChild(loadingDiv);
                                    pdf.save('Appointment_Analytics_Report_' + new Date().toISOString().split('T')[0] + '.pdf');
                                }
                            });
                        });
                    });
                });
            }
        </script>
    </body>
</html>
