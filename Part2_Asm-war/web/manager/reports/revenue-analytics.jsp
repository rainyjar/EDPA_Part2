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
<%@ page import="java.math.BigDecimal" %>

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
    TreatmentFacade treatmentFacade = null;
    PaymentFacade paymentFacade = null;

    try {
        InitialContext ctx = new InitialContext();
        appointmentFacade = (AppointmentFacade) ctx.lookup("java:global/Part2_Asm/Part2_Asm-ejb/AppointmentFacade!model.AppointmentFacade");
        doctorFacade = (DoctorFacade) ctx.lookup("java:global/Part2_Asm/Part2_Asm-ejb/DoctorFacade!model.DoctorFacade");
        treatmentFacade = (TreatmentFacade) ctx.lookup("java:global/Part2_Asm/Part2_Asm-ejb/TreatmentFacade!model.TreatmentFacade");
        paymentFacade = (PaymentFacade) ctx.lookup("java:global/Part2_Asm/Part2_Asm-ejb/PaymentFacade!model.PaymentFacade");
    } catch (Exception e) {
        System.out.println("EJB lookup failed: " + e.getMessage());
    }

    // Initialize data structures
    List<Appointment> allAppointments = new ArrayList<Appointment>();
    List<Doctor> allDoctors = new ArrayList<Doctor>();
    List<Treatment> allTreatments = new ArrayList<Treatment>();
    List<Payment> allPayments = new ArrayList<Payment>();

    double totalRevenue = 0.0;
    double monthlyRevenue = 0.0;
    double avgMonthlyRevenue = 0.0;
    double topDoctorRevenue = 0.0;

    // Monthly revenue tracking (last 12 months)
    double[] monthlyRevenueData = new double[12];
    String[] monthNames = new String[12];

    // Payment status counters
    int paidCount = 0;
    int pendingCount = 0;
    // int overdueCount = 0;

    // Doctor revenue statistics
    final Map<Integer, Double> doctorRevenues = new HashMap<Integer, Double>();
    final Map<Integer, Integer> doctorAppointmentCounts = new HashMap<Integer, Integer>();
    final Map<Integer, Integer> doctorCompletedCounts = new HashMap<Integer, Integer>();

    // Specialization revenue tracking
    final Map<String, Double> specializationRevenues = new HashMap<String, Double>();

    // Fetch real data from EJBs
    if (appointmentFacade != null && doctorFacade != null && paymentFacade != null) {
        try {
            // Get all appointments, doctors, treatments, and payments
            allAppointments = appointmentFacade.findAll();
            allDoctors = doctorFacade.findAll();
            if (treatmentFacade != null) {
                allTreatments = treatmentFacade.findAll();
            }
            allPayments = paymentFacade.findAll();

            // Initialize doctor and specialization counters
            for (Doctor doctor : allDoctors) {
                doctorRevenues.put(doctor.getId(), 0.0);
                doctorAppointmentCounts.put(doctor.getId(), 0);
                doctorCompletedCounts.put(doctor.getId(), 0);

                String specialization = doctor.getSpecialization() != null ? doctor.getSpecialization() : "General";
                specializationRevenues.put(specialization, specializationRevenues.getOrDefault(specialization, 0.0));
            }

            // Initialize month names (last 12 months)
            Calendar cal = Calendar.getInstance();
            SimpleDateFormat monthFormat = new SimpleDateFormat("MMM yyyy");
            for (int i = 11; i >= 0; i--) {
                cal.add(Calendar.MONTH, -i);
                monthNames[11 - i] = monthFormat.format(cal.getTime());
                if (i > 0) {
                    cal.add(Calendar.MONTH, i); // Reset for next iteration
                }
            }

            // Get current month for monthly revenue calculation
            Calendar currentCal = Calendar.getInstance();
            int currentMonth = currentCal.get(Calendar.MONTH);
            int currentYear = currentCal.get(Calendar.YEAR);

            // Process payments for revenue calculations
            for (Payment payment : allPayments) {
                if (payment.getAppointment() != null && "paid".equalsIgnoreCase(payment.getStatus())) {
                    Appointment appointment = payment.getAppointment();
                    double paymentAmount = payment.getAmount();

                    totalRevenue += paymentAmount;

                    // Count by doctor
                    if (appointment.getDoctor() != null) {
                        Integer doctorId = appointment.getDoctor().getId();
                        doctorRevenues.put(doctorId, doctorRevenues.getOrDefault(doctorId, 0.0) + paymentAmount);

                        // Count by specialization
                        String specialization = appointment.getDoctor().getSpecialization() != null
                                ? appointment.getDoctor().getSpecialization() : "General";
                        specializationRevenues.put(specialization,
                                specializationRevenues.getOrDefault(specialization, 0.0) + paymentAmount);
                    }

                    // Calculate monthly revenue and trends using payment date
                    try {
                        if (payment.getPaymentDate() != null) {
                            Calendar paymentCal = Calendar.getInstance();
                            paymentCal.setTime(payment.getPaymentDate());

                            // Check if this is current month revenue
                            if (paymentCal.get(Calendar.MONTH) == currentMonth
                                    && paymentCal.get(Calendar.YEAR) == currentYear) {
                                monthlyRevenue += paymentAmount;
                            }

                            // Add to monthly trends (last 12 months)
                            for (int i = 0; i < 12; i++) {
                                Calendar checkCal = Calendar.getInstance();
                                checkCal.add(Calendar.MONTH, -(11 - i));

                                if (paymentCal.get(Calendar.YEAR) == checkCal.get(Calendar.YEAR)
                                        && paymentCal.get(Calendar.MONTH) == checkCal.get(Calendar.MONTH)) {
                                    monthlyRevenueData[i] += paymentAmount;
                                    break;
                                }
                            }
                        }
                    } catch (Exception e) {
                        System.out.println("[DEBUG] Error parsing payment date: " + e.getMessage());
                    }
                }
            }

            // Process appointments for appointment counts and payment status
            for (Appointment appointment : allAppointments) {
                // Count all appointments by doctor (for appointment count statistics)
                if (appointment.getDoctor() != null) {
                    Integer doctorId = appointment.getDoctor().getId();
                    doctorAppointmentCounts.put(doctorId, doctorAppointmentCounts.getOrDefault(doctorId, 0) + 1);

                    // Count completed appointments
                    String status = appointment.getStatus();
                    if (status != null && ("Completed".equalsIgnoreCase(status) || "Complete".equalsIgnoreCase(status))) {
                        doctorCompletedCounts.put(doctorId, doctorCompletedCounts.getOrDefault(doctorId, 0) + 1);
                    }
                }

                // Count payment status based on payments
                boolean hasPayment = false;
                boolean isPaid = false;
                for (Payment payment : allPayments) {
                    if (payment.getAppointment() != null && payment.getAppointment().getId() == appointment.getId()) {
                        hasPayment = true;
                        if ("paid".equalsIgnoreCase(payment.getStatus())) {
                            isPaid = true;
                            paidCount++;
                            break;
                        } else if ("pending".equalsIgnoreCase(payment.getStatus())) {
                            pendingCount++;
                            break;
                        }
                    }
                }
            }

            // Calculate average monthly revenue
            double totalMonthlyRevenue = 0.0;
            int nonZeroMonths = 0;
            for (double monthRev : monthlyRevenueData) {
                if (monthRev > 0) {
                    totalMonthlyRevenue += monthRev;
                    nonZeroMonths++;
                }
            }
            avgMonthlyRevenue = nonZeroMonths > 0 ? totalMonthlyRevenue / nonZeroMonths : 0.0;

            // Find top doctor revenue
            for (Double revenue : doctorRevenues.values()) {
                if (revenue > topDoctorRevenue) {
                    topDoctorRevenue = revenue;
                }
            }

            // Debug output
            System.out.println("[DEBUG] Total Revenue: RM " + totalRevenue);
            System.out.println("[DEBUG] Monthly Revenue: RM " + monthlyRevenue);
            System.out.println("[DEBUG] Average Monthly Revenue: RM " + avgMonthlyRevenue);
            System.out.println("[DEBUG] Top Doctor Revenue: RM " + topDoctorRevenue);
            System.out.println("[DEBUG] Total Payments Found: " + allPayments.size());
            System.out.println("[DEBUG] Total Doctors Found: " + allDoctors.size());
            System.out.println("[DEBUG] Doctor Revenues Map Size: " + doctorRevenues.size());
            
            // Debug individual doctor revenues
            for (Map.Entry<Integer, Double> entry : doctorRevenues.entrySet()) {
                if (entry.getValue() > 0) {
                    System.out.println("[DEBUG] Doctor ID " + entry.getKey() + " has revenue: RM " + entry.getValue());
                }
            }
           // System.out.println("[DEBUG] Payment Status - Paid: " + paidCount + ", Pending: " + pendingCount + ", Overdue: " + overdueCount);
            
        } catch (Exception e) {
            System.out.println("Error fetching revenue data: " + e.getMessage());
            e.printStackTrace();
        }
    }

    DecimalFormat df = new DecimalFormat("#.##");
%>

<!DOCTYPE html>
<html lang="en">
    <head>
        <title>Revenue Analytics Report - APU Medical Center</title>
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
                            <i class="fa fa-money" style="color:white"></i>
                            <span style="color:white">Revenue Analytics Report</span>
                        </h1>
                        <p class="lead wow fadeInUp" data-wow-delay="0.2s" style="color: whitesmoke">
                            Monthly trends, doctor revenue, and financial insights
                        </p>
                        <nav aria-label="breadcrumb" class="wow fadeInUp" data-wow-delay="0.3s">
                            <ol class="breadcrumb" style="background: transparent; margin: 0;">
                                <li class="breadcrumb-item">
                                    <a href="<%= request.getContextPath()%>/ManagerHomepageServlet" style="color: rgba(255,255,255,0.8);">Dashboard</a>
                                </li>
                                <li class="breadcrumb-item">
                                    <a href="<%= request.getContextPath()%>/manager/reports.jsp" style="color: rgba(255,255,255,0.8);">Reports</a>
                                </li>
                                <li class="breadcrumb-item active" style="color: white;">Revenue Analytics</li>
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
                                <i class="fa fa-money"></i>
                            </div>
                            <div class="kpi-content">
                                <h3 id="totalRevenue">RM 0</h3>
                                <p>Total Revenue</p>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-3 col-sm-6">
                        <div class="kpi-card">
                            <div class="kpi-icon" style="background: linear-gradient(45deg, #f41212 0%, #2c2577 100%);">
                                <i class="fa fa-calendar"></i>
                            </div>
                            <div class="kpi-content">
                                <h3 id="monthlyRevenue">RM 0</h3>
                                <p>Revenue This Month</p>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-3 col-sm-6">
                        <div class="kpi-card">
                            <div class="kpi-icon" style="background: linear-gradient(45deg, #2c2577 0%, #f41212 100%);">
                                <i class="fa fa-line-chart"></i>
                            </div>
                            <div class="kpi-content">
                                <h3 id="avgMonthlyRevenue">RM 0</h3>
                                <p>Avg Revenue Monthly</p>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-3 col-sm-6">
                        <div class="kpi-card">
                            <div class="kpi-icon" style="background: linear-gradient(45deg, #f41212 0%, #2c2577 100%);">
                                <i class="fa fa-star"></i>
                            </div>
                            <div class="kpi-content">
                                <h3 id="topDoctorRevenue">RM 0</h3>
                                <p>Top Doctor Revenue</p>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Charts Row -->
                <div class="row charts-row">
                    <!-- Monthly Revenue Trends -->
                    <div class="col-md-8">
                        <div class="chart-container">
                            <div class="chart-header">
                                <h3><i class="fa fa-line-chart"></i> Monthly Revenue Trends (Last 12 Months)</h3>
                            </div>
                            <div class="chart-body">
                                <canvas id="monthlyTrendsChart"></canvas>
                            </div>
                        </div>
                    </div>

                    <!-- Payment Status Distribution -->
                    <div class="col-md-4">
                        <div class="chart-container">
                            <div class="chart-header">
                                <h3><i class="fa fa-pie-chart"></i> Payment Status</h3>
                            </div>
                            <div class="chart-body">
                                <canvas id="paymentStatusChart"></canvas>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Second Charts Row -->
                <div class="row charts-row">
                    <!-- Top Revenue Generating Doctors -->
                    <div class="col-md-6">
                        <div class="chart-container">
                            <div class="chart-header">
                                <h3><i class="fa fa-bar-chart"></i> Top Revenue Generating Doctors</h3>
                            </div>
                            <div class="chart-body">
                                <canvas id="doctorRevenueChart"></canvas>
                            </div>
                        </div>
                    </div>

                    <!-- Revenue by Specialization -->
                    <div class="col-md-6">
                        <div class="chart-container">
                            <div class="chart-header">
                                <h3><i class="fa fa-stethoscope"></i> Revenue by Specialization</h3>
                            </div>
                            <div class="chart-body">
                                <canvas id="specializationRevenueChart"></canvas>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Detailed Tables -->
                <div class="row tables-row">
                    <!-- Doctor Revenue Table -->
                    <div class="col-md-12">
                        <div class="table-container">
                            <div class="table-header">
                                <h3><i class="fa fa-table"></i> Doctor Revenue Details</h3>
                            </div>
                            <div class="table-body">
                                <table class="table table-striped performance-table">
                                    <thead>
                                        <tr>
                                            <th>Rank</th>
                                            <th>Doctor Name</th>
                                            <th>Specialization</th>
                                            <th>Total Appointments</th>
                                            <th>Completed</th>
                                            <th>Total Revenue</th>
                                            <th>Avg per Appointment</th>
                                        </tr>
                                    </thead>
                                    <tbody id="doctorRevenueTable">
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
            let monthlyTrendsChart, paymentStatusChart, doctorRevenueChart, specializationRevenueChart;
            $(document).ready(function () {
            loadRevenueAnalyticsData();
            });
            function loadRevenueAnalyticsData() {
            // Use real data from JSP/EJB instead of mock data
            const realData = {
            totalRevenue: <%= totalRevenue%>,
                    monthlyRevenue: <%= monthlyRevenue%>,
                    avgMonthlyRevenue: <%= avgMonthlyRevenue%>,
                    topDoctorRevenue: <%= topDoctorRevenue%>,
                    monthlyTrends: {
                    labels: [
            <%
                for (int i = 0; i < monthNames.length; i++) {
                    if (i > 0) {
                        out.print(", ");
                    }
                    out.print("'" + monthNames[i] + "'");
                }
            %>
                    ],
                            data: [<%= monthlyRevenueData[0]%>, <%= monthlyRevenueData[1]%>, <%= monthlyRevenueData[2]%>, <%= monthlyRevenueData[3]%>, <%= monthlyRevenueData[4]%>, <%= monthlyRevenueData[5]%>, <%= monthlyRevenueData[6]%>, <%= monthlyRevenueData[7]%>, <%= monthlyRevenueData[8]%>, <%= monthlyRevenueData[9]%>, <%= monthlyRevenueData[10]%>, <%= monthlyRevenueData[11]%>]
                    },
                    paymentStatus: {
                    // labels: ['Paid', 'Pending', 'Overdue'],
                    labels: ['Paid', 'Pending'],
                            
                            data: [<%= paidCount%>, <%= pendingCount%>]
                            
//                             data: + overdueCount
                    },
                    topDoctors: [
            <%
                // Create a list of doctors sorted by revenue
                List<Doctor> sortedDoctors = new ArrayList<Doctor>();
                for (Doctor doctor : allDoctors) {
                    if (doctorRevenues.get(doctor.getId()) > 0) {
                        sortedDoctors.add(doctor);
                    }
                }

                // Sort by revenue (descending)
                Collections.sort(sortedDoctors, new Comparator<Doctor>() {
                    public int compare(Doctor d1, Doctor d2) {
                        Double revenue1 = doctorRevenues.get(d1.getId());
                        Double revenue2 = doctorRevenues.get(d2.getId());
                        return revenue2.compareTo(revenue1);
                    }
                });

                // Output top 5 doctors
                for (int i = 0; i < Math.min(5, sortedDoctors.size()); i++) {
                    Doctor doctor = sortedDoctors.get(i);
                    double revenue = doctorRevenues.get(doctor.getId());
                    int appointments = doctorAppointmentCounts.get(doctor.getId());
                    int completed = doctorCompletedCounts.get(doctor.getId());

                    if (i > 0) {
                        out.print(",");
                    }
            %>
                    {
                    name: '<%= "Dr. " + doctor.getName().replace("'", "\\'")%>',
                            specialization: '<%= doctor.getSpecialization() != null ? doctor.getSpecialization().replace("'", "\\'") : "General"%>',
                            appointments: <%= appointments%>,
                            completed: <%= completed%>,
                            revenue: <%= revenue%>
                    }
            <%
                }
            %>
                    ],
                    specializationRevenue: {
                    labels: [
            <%
                // Get specializations and sort by revenue
                List<Map.Entry<String, Double>> specializationList = new ArrayList<Map.Entry<String, Double>>(specializationRevenues.entrySet());
                Collections.sort(specializationList, new Comparator<Map.Entry<String, Double>>() {
                    public int compare(Map.Entry<String, Double> a, Map.Entry<String, Double> b) {
                        return b.getValue().compareTo(a.getValue());
                    }
                });

                for (int i = 0; i < specializationList.size(); i++) {
                    if (i > 0) {
                        out.print(", ");
                    }
                    out.print("'" + specializationList.get(i).getKey().replace("'", "\\'") + "'");
                }
            %>
                    ],
                            data: [
            <%
                for (int i = 0; i < specializationList.size(); i++) {
                    if (i > 0) {
                        out.print(", ");
                    }
                    out.print(df.format(specializationList.get(i).getValue()));
                }
            %>
                            ]
                    }
            };
            updateKPIs(realData);
            createCharts(realData);
            populateTables(realData);
            }

            function updateKPIs(data) {
            $('#totalRevenue').text('RM ' + data.totalRevenue.toLocaleString());
            $('#monthlyRevenue').text('RM ' + data.monthlyRevenue.toLocaleString());
            $('#avgMonthlyRevenue').text('RM ' + data.avgMonthlyRevenue.toLocaleString());
            $('#topDoctorRevenue').text('RM ' + data.topDoctorRevenue.toLocaleString());
            }

            function createCharts(data) {
            // Monthly Trends Chart
            const monthlyCtx = document.getElementById('monthlyTrendsChart').getContext('2d');
            monthlyTrendsChart = new Chart(monthlyCtx, {
            type: 'line',
                    data: {
                    labels: data.monthlyTrends.labels,
                            datasets: [{
                            label: 'Revenue (RM)',
                                    data: data.monthlyTrends.data,
                                    borderColor: 'rgba(244, 18, 18, 1)',
                                    backgroundColor: 'rgba(244, 18, 18, 0.1)',
                                    fill: true,
                                    tension: 0.4
                            }]
                    },
                    options: {
                    responsive: true,
                            maintainAspectRatio: false,
                            scales: {
                            y: {
                            beginAtZero: true,
                                    ticks: {
                                    callback: function (value) {
                                    return 'RM ' + value.toLocaleString();
                                    }
                                    }
                            }
                            }
                    }
            });
            // Payment Status Chart
            const paymentCtx = document.getElementById('paymentStatusChart').getContext('2d');
            paymentStatusChart = new Chart(paymentCtx, {
            type: 'doughnut',
                    data: {
                    labels: data.paymentStatus.labels,
                            datasets: [{
                            data: data.paymentStatus.data,
                                    backgroundColor: [
                                            'rgba(40, 167, 69, 0.8)',    // Green for Paid
                                            'rgba(255, 193, 7, 0.8)',    // Yellow for Pending
                                            'rgba(244, 18, 18, 0.8)'     // Red for Overdue (when implemented)
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
            // Doctor Revenue Chart
            const doctorCtx = document.getElementById('doctorRevenueChart').getContext('2d');
            doctorRevenueChart = new Chart(doctorCtx, {
            type: 'bar',
                    data: {
                    labels: data.topDoctors.map(d => d.name.replace('Dr. ', '')),
                            datasets: [{
                            label: 'Revenue (RM)',
                                    data: data.topDoctors.map(d => d.revenue),
                                    backgroundColor: 'rgba(44, 37, 119, 0.8)',
                                    borderColor: 'rgba(44, 37, 119, 1)',
                                    borderWidth: 1
                            }]
                    },
                    options: {
                    responsive: true,
                            maintainAspectRatio: false,
                            scales: {
                            y: {
                            beginAtZero: true,
                                    ticks: {
                                    callback: function (value) {
                                    return 'RM ' + value.toLocaleString();
                                    }
                                    }
                            }
                            }
                    }
            });
            // Specialization Revenue Chart
            const specializationCtx = document.getElementById('specializationRevenueChart').getContext('2d');
            specializationRevenueChart = new Chart(specializationCtx, {
            type: 'polarArea',
                    data: {
                    labels: data.specializationRevenue.labels,
                            datasets: [{
                            data: data.specializationRevenue.data,
                                    backgroundColor: [
                                            'rgba(244, 18, 18, 0.8)',
                                            'rgba(44, 37, 119, 0.8)',
                                            'rgba(255, 193, 7, 0.8)',
                                            'rgba(40, 167, 69, 0.8)',
                                            'rgba(108, 117, 125, 0.8)',
                                            'rgba(255, 99, 132, 0.8)'
                                    ]
                            }]
                    },
                    options: {
                    responsive: true,
                            maintainAspectRatio: false
                    }
            });
            }

            function populateTables(data) {
            console.log('[DEBUG] populateTables called with data:', data);
            console.log('[DEBUG] topDoctors array:', data.topDoctors);
            console.log('[DEBUG] topDoctors length:', data.topDoctors.length);
            
            let tableHtml = '';
            data.topDoctors.forEach((doctor, index) => {
            console.log('[DEBUG] Processing doctor:', doctor);
            console.log('[DEBUG] Doctor name:', doctor.name);
            console.log('[DEBUG] Doctor specialization:', doctor.specialization);
            console.log('[DEBUG] Doctor appointments:', doctor.appointments);
            console.log('[DEBUG] Doctor completed:', doctor.completed);
            console.log('[DEBUG] Doctor revenue:', doctor.revenue);
            
            const avgPerAppointment = doctor.completed > 0 ? (doctor.revenue / doctor.completed) : 0;
            console.log('[DEBUG] Calculated avgPerAppointment:', avgPerAppointment);
            
            tableHtml += '<tr>';
            tableHtml += '<td>' + (index + 1) + '</td>';
            tableHtml += '<td>' + doctor.name + '</td>';
            tableHtml += '<td>' + doctor.specialization + '</td>';
            tableHtml += '<td>' + doctor.appointments + '</td>';
            tableHtml += '<td>' + doctor.completed + '</td>';
            tableHtml += '<td>RM ' + doctor.revenue.toLocaleString() + '</td>';
            tableHtml += '<td>RM ' + avgPerAppointment.toFixed(2) + '</td>';
            tableHtml += '</tr>';
            });
            
            console.log('[DEBUG] Generated table HTML:', tableHtml);
            $('#doctorRevenueTable').html(tableHtml);
            console.log('[DEBUG] Table updated. Current table content:', $('#doctorRevenueTable').html());
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
            pdf.text('Revenue Analytics Report', 20, currentY);
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
            pdf.text('Revenue Summary', 20, currentY);
            currentY += 10;
            pdf.setFontSize(11);
            pdf.setTextColor(0, 0, 0);
            pdf.text('Total Revenue: RM <%= df.format(totalRevenue)%>', 20, currentY);
            pdf.text('Monthly Revenue: RM <%= df.format(monthlyRevenue)%>', 110, currentY);
            currentY += 7;
            pdf.text('Average Monthly: RM <%= df.format(avgMonthlyRevenue)%>', 20, currentY);
            pdf.text('Top Doctor Revenue: RM <%= df.format(topDoctorRevenue)%>', 110, currentY);
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
            addChartToPDF('monthlyTrendsChart', 'Monthly Revenue Trends', function () {
            addChartToPDF('paymentStatusChart', 'Payment Status Distribution', function () {
            addChartToPDF('doctorRevenueChart', 'Top Revenue Generating Doctors', function () {
            addChartToPDF('specializationRevenueChart', 'Revenue by Specialization', function () {
            // Add a new page for tables
            pdf.addPage();
            currentY = 20;
            // Add tables section header
            pdf.setFontSize(18);
            pdf.setTextColor(44, 37, 119);
            pdf.text('Doctor Revenue Details', 20, currentY);
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
            pdf.save('Revenue_Analytics_Report_' + new Date().toISOString().split('T')[0] + '.pdf');
            }).catch(function (error) {
            console.error('Error capturing table:', error);
            document.body.removeChild(loadingDiv);
            pdf.save('Revenue_Analytics_Report_' + new Date().toISOString().split('T')[0] + '.pdf');
            });
            } else {
            // If table not found, just finish without table
            document.body.removeChild(loadingDiv);
            pdf.save('Revenue_Analytics_Report_' + new Date().toISOString().split('T')[0] + '.pdf');
            }
            });
            });
            });
            });
            }
        </script>
    </body>
</html>
