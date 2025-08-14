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
<%@ page import="java.time.LocalDate" %>
<%@ page import="java.time.Period" %>
<%@ page import="java.time.ZoneId" %>

<%
    // Check if manager is logged in
    Manager loggedInManager = (Manager) session.getAttribute("manager");
    if (loggedInManager == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    // Get EJB facades using JNDI lookup
    CustomerFacade customerFacade = null;
    AppointmentFacade appointmentFacade = null;
    TreatmentFacade treatmentFacade = null;

    try {
        InitialContext ctx = new InitialContext();
        customerFacade = (CustomerFacade) ctx.lookup("java:global/Part2_Asm/Part2_Asm-ejb/CustomerFacade!model.CustomerFacade");
        appointmentFacade = (AppointmentFacade) ctx.lookup("java:global/Part2_Asm/Part2_Asm-ejb/AppointmentFacade!model.AppointmentFacade");
        treatmentFacade = (TreatmentFacade) ctx.lookup("java:global/Part2_Asm/Part2_Asm-ejb/TreatmentFacade!model.TreatmentFacade");
    } catch (Exception e) {
        System.out.println("EJB lookup failed: " + e.getMessage());
    }

    // Initialize data structures
    List<Customer> allCustomers = new ArrayList<Customer>();
    List<Appointment> allAppointments = new ArrayList<Appointment>();
    List<Treatment> allTreatments = new ArrayList<Treatment>();

    int totalCustomers = 0;
    int newCustomers = 0;
    String peakHour = "N/A";
    String popularTreatment = "N/A";

    // Age distribution tracking
    int[] ageDistribution = {0, 0, 0, 0, 0}; // 18-25, 26-35, 36-45, 46-55, 56+
    String[] ageLabels = {"18-25", "26-35", "36-45", "46-55", "56+"};

    // Peak hours tracking (9 AM to 5 PM)
    Map<String, Integer> peakHours = new HashMap<String, Integer>();
    String[] hourLabels = {"09-10", "10-11", "11-12", "12-13", "13-14", "14-15", "15-16", "16-17"};
    for (String hour : hourLabels) {
        peakHours.put(hour, 0);
    }

    // Treatment popularity tracking
    Map<String, Integer> treatmentCounts = new HashMap<String, Integer>();

    // Visit patterns tracking
    Map<String, Integer> visitPatterns = new HashMap<String, Integer>();
    visitPatterns.put("First-time", 0);
    visitPatterns.put("2-3 visits/year", 0);
    visitPatterns.put("4-6 visits/year", 0);
    visitPatterns.put("7+ visits/year", 0);

    // Gender distribution
    int maleCount = 0;
    int femaleCount = 0;

    // Monthly growth tracking (last 7 months)
    int[] monthlyGrowth = new int[7];
    String[] monthNames = new String[7];

    // Fetch real data from EJBs
    if (customerFacade != null && appointmentFacade != null && treatmentFacade != null) {
        try {
            // Get all customers, appointments, and treatments
            allCustomers = customerFacade.findAll();
            allAppointments = appointmentFacade.findAll();
            allTreatments = treatmentFacade.findAll();

            totalCustomers = allCustomers.size();

            // Initialize treatment counts
            for (Treatment treatment : allTreatments) {
                treatmentCounts.put(treatment.getName(), 0);
            }

            // Calculate current month for new customers
            Calendar currentCal = Calendar.getInstance();
            int currentMonth = currentCal.get(Calendar.MONTH);
            int currentYear = currentCal.get(Calendar.YEAR);

            // Initialize month names for growth tracking
            SimpleDateFormat monthFormat = new SimpleDateFormat("MMM");
            for (int i = 6; i >= 0; i--) {
                Calendar cal = Calendar.getInstance();
                cal.add(Calendar.MONTH, -i);
                monthNames[6 - i] = monthFormat.format(cal.getTime());
                monthlyGrowth[6 - i] = 0;
            }

            // Process customers for analytics
            for (Customer customer : allCustomers) {
                // Gender distribution
                if (customer.getGender() != null) {
                    if ("Male".equalsIgnoreCase(customer.getGender()) || "M".equalsIgnoreCase(customer.getGender())) {
                        maleCount++;
                    } else if ("Female".equalsIgnoreCase(customer.getGender()) || "F".equalsIgnoreCase(customer.getGender())) {
                        femaleCount++;
                    }
                }

                // Age distribution
                if (customer.getDob() != null) {
                    LocalDate birthDate = customer.getDob().toInstant().atZone(ZoneId.systemDefault()).toLocalDate();
                    LocalDate currentDate = LocalDate.now();
                    int age = Period.between(birthDate, currentDate).getYears();

                    if (age >= 18 && age <= 25) {
                        ageDistribution[0]++;
                    } else if (age >= 26 && age <= 35) {
                        ageDistribution[1]++;
                    } else if (age >= 36 && age <= 45) {
                        ageDistribution[2]++;
                    } else if (age >= 46 && age <= 55) {
                        ageDistribution[3]++;
                    } else if (age >= 56) {
                        ageDistribution[4]++;
                    }
                }

                // Count customer appointments for visit patterns
                int appointmentCount = 0;
                if (customer.getAppointments() != null) {
                    appointmentCount = customer.getAppointments().size();
                }

                if (appointmentCount == 1) {
                    visitPatterns.put("First-time", visitPatterns.get("First-time") + 1);
                } else if (appointmentCount >= 2 && appointmentCount <= 3) {
                    visitPatterns.put("2-3 visits/year", visitPatterns.get("2-3 visits/year") + 1);
                } else if (appointmentCount >= 4 && appointmentCount <= 6) {
                    visitPatterns.put("4-6 visits/year", visitPatterns.get("4-6 visits/year") + 1);
                } else if (appointmentCount >= 7) {
                    visitPatterns.put("7+ visits/year", visitPatterns.get("7+ visits/year") + 1);
                }
            }

            // Process appointments for peak hours and treatment popularity
            for (Appointment appointment : allAppointments) {
                // Peak hours analysis
                if (appointment.getAppointmentTime() != null) {
                    String timeStr = appointment.getAppointmentTime().toString();
                    int hour = Integer.parseInt(timeStr.split(":")[0]);

                    for (String hourLabel : hourLabels) {
                        String[] range = hourLabel.split("-");
                        int startHour = Integer.parseInt(range[0]);
                        int endHour = Integer.parseInt(range[1]);

                        if (hour >= startHour && hour < endHour) {
                            peakHours.put(hourLabel, peakHours.get(hourLabel) + 1);
                            break;
                        }
                    }
                }

                // Treatment popularity
                if (appointment.getTreatment() != null) {
                    String treatmentName = appointment.getTreatment().getName();
                    treatmentCounts.put(treatmentName, treatmentCounts.getOrDefault(treatmentName, 0) + 1);
                }

                // New customers this month (based on first appointment)
                if (appointment.getAppointmentDate() != null && appointment.getCustomer() != null) {
                    Calendar appointmentCal = Calendar.getInstance();
                    appointmentCal.setTime(appointment.getAppointmentDate());

                    if (appointmentCal.get(Calendar.MONTH) == currentMonth
                            && appointmentCal.get(Calendar.YEAR) == currentYear) {
                        // Check if this is customer's first appointment
                        boolean isFirstAppointment = true;
                        for (Appointment otherApp : allAppointments) {
                            if (otherApp.getCustomer() != null
                                    && otherApp.getCustomer().getId() == appointment.getCustomer().getId()
                                    && otherApp.getAppointmentDate() != null
                                    && otherApp.getAppointmentDate().before(appointment.getAppointmentDate())) {
                                isFirstAppointment = false;
                                break;
                            }
                        }
                        if (isFirstAppointment) {
                            newCustomers++;
                        }
                    }

                    // Monthly growth tracking
                    for (int i = 0; i < 7; i++) {
                        Calendar checkCal = Calendar.getInstance();
                        checkCal.add(Calendar.MONTH, -(6 - i));

                        if (appointmentCal.get(Calendar.YEAR) == checkCal.get(Calendar.YEAR)
                                && appointmentCal.get(Calendar.MONTH) == checkCal.get(Calendar.MONTH)) {
                            monthlyGrowth[i]++;
                            break;
                        }
                    }
                }
            }

            // Find peak hour
            int maxHourlyAppointments = 0;
            for (Map.Entry<String, Integer> entry : peakHours.entrySet()) {
                if (entry.getValue() > maxHourlyAppointments) {
                    maxHourlyAppointments = entry.getValue();
                    peakHour = entry.getKey();
                }
            }

            // Find most popular treatment
            int maxTreatmentCount = 0;
            for (Map.Entry<String, Integer> entry : treatmentCounts.entrySet()) {
                if (entry.getValue() > maxTreatmentCount) {
                    maxTreatmentCount = entry.getValue();
                    popularTreatment = entry.getKey();
                }
            }

            // Debug output
            System.out.println("[DEBUG] Customer Analytics - Total Customers: " + totalCustomers);
            System.out.println("[DEBUG] Customer Analytics - New Customers: " + newCustomers);
            System.out.println("[DEBUG] Customer Analytics - Peak Hour: " + peakHour);
            System.out.println("[DEBUG] Customer Analytics - Popular Treatment: " + popularTreatment);
            System.out.println("[DEBUG] Customer Analytics - Gender Distribution - Male: " + maleCount + ", Female: " + femaleCount);

            // Debug age distribution
            for (int i = 0; i < ageLabels.length; i++) {
                System.out.println("[DEBUG] Age Group " + ageLabels[i] + ": " + ageDistribution[i] + " customers");
            }

            // Debug visit patterns
            for (Map.Entry<String, Integer> entry : visitPatterns.entrySet()) {
                System.out.println("[DEBUG] Visit Pattern " + entry.getKey() + ": " + entry.getValue() + " customers");
            }

            // Debug treatment popularity
            for (Map.Entry<String, Integer> entry : treatmentCounts.entrySet()) {
                if (entry.getValue() > 0) {
                    System.out.println("[DEBUG] Treatment " + entry.getKey() + ": " + entry.getValue() + " appointments");
                }
            }

        } catch (Exception e) {
            System.out.println("Error fetching customer analytics data: " + e.getMessage());
            e.printStackTrace();
        }
    }

    DecimalFormat df = new DecimalFormat("#.##");
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
        <style>
            .kpi-content h3 {
                font-size: 1em;
                font-weight: 700;
                color: #2c3e50;
                margin: 0;
            }
        </style>
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
                                <p>New Customer This Month</p>
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
                                <p>Peak Operation Hour</p>
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
                                <p>Most Popular Treatment</p>
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
                                            <th>Avg Appointments</th>
                                            <th>Most Popular Treatment</th>
                                            <th>Preferred Time</th>
                                        </tr>
                                    </thead>
                                    <tbody id="customerAnalyticsTable">
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
            // Use real data from JSP/EJB instead of mock data
            const realData = {
            totalCustomers: <%= totalCustomers%>,
                    newCustomers: <%= newCustomers%>,
                    peakHour: '<%= peakHour%>',
                    popularTreatment: '<%= popularTreatment%>',
                    ageDistribution: {
                    labels: ['<%= ageLabels[0]%>', '<%= ageLabels[1]%>', '<%= ageLabels[2]%>', '<%= ageLabels[3]%>', '<%= ageLabels[4]%>'],
                            data: [<%= ageDistribution[0]%>, <%= ageDistribution[1]%>, <%= ageDistribution[2]%>, <%= ageDistribution[3]%>, <%= ageDistribution[4]%>]
                    },
                    peakHours: {
                    labels: [
            <%
                for (int i = 0; i < hourLabels.length; i++) {
                    if (i > 0) {
                        out.print(", ");
                    }
                    out.print("'" + hourLabels[i] + "'");
                }
            %>
                    ],
                            data: [
            <%
                for (int i = 0; i < hourLabels.length; i++) {
                    if (i > 0) {
                        out.print(", ");
                    }
                    out.print(peakHours.get(hourLabels[i]));
                }
            %>
                            ]
                    },
                    popularTreatments: {
                    labels: [
            <%
                // Get treatments sorted by popularity
                List<Map.Entry<String, Integer>> treatmentList = new ArrayList<Map.Entry<String, Integer>>(treatmentCounts.entrySet());
                Collections.sort(treatmentList, new Comparator<Map.Entry<String, Integer>>() {
                    public int compare(Map.Entry<String, Integer> a, Map.Entry<String, Integer> b) {
                        return b.getValue().compareTo(a.getValue());
                    }
                });

                for (int i = 0; i < Math.min(5, treatmentList.size()); i++) {
                    if (i > 0) {
                        out.print(", ");
                    }
                    out.print("'" + treatmentList.get(i).getKey().replace("'", "\\'") + "'");
                }
            %>
                    ],
                            data: [
            <%
                for (int i = 0; i < Math.min(5, treatmentList.size()); i++) {
                    if (i > 0) {
                        out.print(", ");
                    }
                    out.print(treatmentList.get(i).getValue());
                }
            %>
                            ]
                    },
                    visitPatterns: {
                    labels: ['First-time', '2-3 visits/year', '4-6 visits/year', '7+ visits/year'],
                            data: [<%= visitPatterns.get("First-time")%>, <%= visitPatterns.get("2-3 visits/year")%>, <%= visitPatterns.get("4-6 visits/year")%>, <%= visitPatterns.get("7+ visits/year")%>]
                    },
                    genderDistribution: {
                    labels: ['Female', 'Male'],
                            data: [<%= femaleCount%>, <%= maleCount%>]
                    },
                    growthTrend: {
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
                            data: [
            <%
                for (int i = 0; i < monthlyGrowth.length; i++) {
                    if (i > 0) {
                        out.print(", ");
                    }
                    out.print(monthlyGrowth[i]);
                }
            %>
                            ]
                    },
                    analyticsBreakdown: [
            <%
                // Create analytics breakdown by age group - show all age groups, use N/A for empty ones
                for (int i = 0; i < ageLabels.length; i++) {
                    if (i > 0) {
                        out.print(",");
                    }

                    int ageGroupTotal = ageDistribution[i];

                    System.out.println("[DEBUG] Processing age group " + ageLabels[i] + " with " + ageGroupTotal + " customers");

                    if (ageGroupTotal > 0) {
                        // Calculate actual gender distribution for this age group
                        int ageGroupMale = 0;
                        int ageGroupFemale = 0;
                        int totalVisits = 0;
                        Map<String, Integer> ageGroupTreatments = new HashMap<String, Integer>();
                        Map<String, Integer> ageGroupTimes = new HashMap<String, Integer>();

                        // Initialize time slots
                        for (String timeSlot : hourLabels) {
                            ageGroupTimes.put(timeSlot, 0);
                        }

                        // Process customers in this age group
                        for (Customer customer : allCustomers) {
                            if (customer.getDob() != null) {
                                LocalDate birthDate = customer.getDob().toInstant().atZone(ZoneId.systemDefault()).toLocalDate();
                                LocalDate currentDate = LocalDate.now();
                                int age = Period.between(birthDate, currentDate).getYears();

                                boolean inThisAgeGroup = false;
                                if (i == 0 && age >= 18 && age <= 25) {
                                    inThisAgeGroup = true;
                                } else if (i == 1 && age >= 26 && age <= 35) {
                                    inThisAgeGroup = true;
                                } else if (i == 2 && age >= 36 && age <= 45) {
                                    inThisAgeGroup = true;
                                } else if (i == 3 && age >= 46 && age <= 55) {
                                    inThisAgeGroup = true;
                                } else if (i == 4 && age >= 56) {
                                    inThisAgeGroup = true;
                                }

                                if (inThisAgeGroup) {
                                    // Count gender
                                    if (customer.getGender() != null) {
                                        if ("Male".equalsIgnoreCase(customer.getGender()) || "M".equalsIgnoreCase(customer.getGender())) {
                                            ageGroupMale++;
                                        } else if ("Female".equalsIgnoreCase(customer.getGender()) || "F".equalsIgnoreCase(customer.getGender())) {
                                            ageGroupFemale++;
                                        }
                                    }

                                    // Count appointments for this customer
                                    int customerAppointments = 0;
                                    for (Appointment appointment : allAppointments) {
                                        if (appointment.getCustomer() != null && appointment.getCustomer().getId() == customer.getId()) {
                                            customerAppointments++;
                                            totalVisits++;

                                            // Count treatments for this age group
                                            if (appointment.getTreatment() != null) {
                                                String treatmentName = appointment.getTreatment().getName();
                                                ageGroupTreatments.put(treatmentName, ageGroupTreatments.getOrDefault(treatmentName, 0) + 1);
                                            }

                                            // Count preferred times for this age group
                                            if (appointment.getAppointmentTime() != null) {
                                                String timeStr = appointment.getAppointmentTime().toString();
                                                int hour = Integer.parseInt(timeStr.split(":")[0]);

                                                for (String hourLabel : hourLabels) {
                                                    String[] range = hourLabel.split("-");
                                                    int startHour = Integer.parseInt(range[0]);
                                                    int endHour = Integer.parseInt(range[1]);

                                                    if (hour >= startHour && hour < endHour) {
                                                        ageGroupTimes.put(hourLabel, ageGroupTimes.get(hourLabel) + 1);
                                                        break;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Calculate average visits
                        double avgVisits = ageGroupTotal > 0 ? (double) totalVisits / ageGroupTotal : 0.0;

                        // Find most popular treatment for this age group
                        String agePopularTreatment = "N/A";
                        int maxTreatmentCount = 0;
                        for (Map.Entry<String, Integer> entry : ageGroupTreatments.entrySet()) {
                            if (entry.getValue() > maxTreatmentCount) {
                                maxTreatmentCount = entry.getValue();
                                agePopularTreatment = entry.getKey();
                            }
                        }

                        // Find preferred time for this age group
                        String preferredTime = "N/A";
                        int maxTimeCount = 0;
                        for (Map.Entry<String, Integer> entry : ageGroupTimes.entrySet()) {
                            if (entry.getValue() > maxTimeCount) {
                                maxTimeCount = entry.getValue();
                                preferredTime = entry.getKey();
                            }
                        }

                        System.out.println("[DEBUG] Age Group " + ageLabels[i] + " Analysis:");
                        System.out.println("  - Total: " + ageGroupTotal);
                        System.out.println("  - Male: " + ageGroupMale + ", Female: " + ageGroupFemale);
                        System.out.println("  - Total Visits: " + totalVisits);
                        System.out.println("  - Average Visits: " + df.format(avgVisits));
                        System.out.println("  - Popular Treatment: " + agePopularTreatment + " (" + maxTreatmentCount + " appointments)");
                        System.out.println("  - Preferred Time: " + preferredTime + " (" + maxTimeCount + " appointments)");
            %>
                    {
                    ageGroup: '<%= ageLabels[i]%>',
                            total: <%= ageGroupTotal%>,
                            male: <%= ageGroupMale%>,
                            female: <%= ageGroupFemale%>,
                            avgVisits: '<%= df.format(avgVisits)%>',
                            popularTreatment: '<%= agePopularTreatment%>',
                            preferredTime: '<%= preferredTime%>'
                    }
            <%
            } else {
                // No customers in this age group - show N/A values
                System.out.println("[DEBUG] Age Group " + ageLabels[i] + " - No customers, showing N/A values");
            %>
                    {
                    ageGroup: '<%= ageLabels[i]%>',
                            total: 0,
                            male: 0,
                            female: 0,
                            avgVisits: 'N/A',
                            popularTreatment: 'N/A',
                            preferredTime: 'N/A'
                    }
            <%
                    }
                }
            %>
                    ]
            }
            ;
            console.log('[DEBUG] Customer Analytics Data:', realData);
            updateKPIs(realData);
            createCharts(realData);
            populateTables(realData);
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
            console.log('[DEBUG] populateTables called with data:', data);
            console.log('[DEBUG] analyticsBreakdown array:', data.analyticsBreakdown);
            let tableHtml = '';
            data.analyticsBreakdown.forEach((row, index) => {
            console.log('[DEBUG] Processing row:', row);
            tableHtml += '<tr>';
            tableHtml += '<td>' + row.ageGroup + '</td>';
            tableHtml += '<td>' + row.total + '</td>';
            tableHtml += '<td>' + row.male + '</td>';
            tableHtml += '<td>' + row.female + '</td>';
            tableHtml += '<td>' + row.avgVisits + '</td>';
            tableHtml += '<td>' + row.popularTreatment + '</td>';
            tableHtml += '<td>' + row.preferredTime + '</td>';
            tableHtml += '</tr>';
            });
            console.log('[DEBUG] Generated table HTML:', tableHtml);
            $('#customerAnalyticsTable').html(tableHtml);
            console.log('[DEBUG] Table updated. Current table content:', $('#customerAnalyticsTable').html());
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
            pdf.text('Customer Analytics Report', 20, currentY);
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
            pdf.text('Customer Summary', 20, currentY);
            currentY += 10;
            pdf.setFontSize(11);
            pdf.setTextColor(0, 0, 0);
            pdf.text('Total Customers: <%= totalCustomers%>', 20, currentY);
            pdf.text('New Customers: <%= newCustomers%>', 110, currentY);
            currentY += 7;
            pdf.text('Peak Hour: <%= peakHour%>', 20, currentY);
            pdf.text('Popular Treatment: <%= popularTreatment%>', 110, currentY);
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
            addChartToPDF('ageDistributionChart', 'Customer Age Distribution', function () {
            addChartToPDF('peakHoursChart', 'Peak Hours Analysis', function () {
            addChartToPDF('popularTreatmentsChart', 'Most Popular Treatments', function () {
            addChartToPDF('visitPatternsChart', 'Customer Visit Patterns', function () {
            addChartToPDF('genderDistributionChart', 'Customer Gender Distribution', function () {
            addChartToPDF('growthTrendChart', 'Customer Growth Trend', function () {
            // Add a new page for tables
            pdf.addPage();
            currentY = 20;
            // Add tables section header
            pdf.setFontSize(18);
            pdf.setTextColor(44, 37, 119);
            pdf.text('Customer Analytics Summary', 20, currentY);
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
            pdf.save('Customer_Analytics_Report_' + new Date().toISOString().split('T')[0] + '.pdf');
            }).catch(function (error) {
            console.error('Error capturing table:', error);
            document.body.removeChild(loadingDiv);
            pdf.save('Customer_Analytics_Report_' + new Date().toISOString().split('T')[0] + '.pdf');
            });
            } else {
            // If table not found, just finish without table
            document.body.removeChild(loadingDiv);
            pdf.save('Customer_Analytics_Report_' + new Date().toISOString().split('T')[0] + '.pdf');
            }
            });
            });
            });
            });
            });
            });
            }
        </script>
    </body>
</html>
