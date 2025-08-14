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
    AppointmentFacade appointmentFacade = null;

    try {
        InitialContext ctx = new InitialContext();
        doctorFacade = (DoctorFacade) ctx.lookup("java:global/Part2_Asm/Part2_Asm-ejb/DoctorFacade!model.DoctorFacade");
        counterStaffFacade = (CounterStaffFacade) ctx.lookup("java:global/Part2_Asm/Part2_Asm-ejb/CounterStaffFacade!model.CounterStaffFacade");
        appointmentFacade = (AppointmentFacade) ctx.lookup("java:global/Part2_Asm/Part2_Asm-ejb/AppointmentFacade!model.AppointmentFacade");
    } catch (Exception e) {
        // Fallback to mock data if EJB lookup fails
        System.out.println("EJB lookup failed: " + e.getMessage());
    }

    // Prepare data structures - Fixed: Remove diamond operators for Java 1.5 compatibility
    List<Doctor> topDoctors = new ArrayList<Doctor>();
    // Updated stats calculation for report
    List<CounterStaff> topStaff = new ArrayList<CounterStaff>();
    int totalDoctors = 0;
    int totalStaff = 0;
    double avgDoctorRating = 0.0;
    int totalAppointments = 0;

    if (doctorFacade != null && counterStaffFacade != null && appointmentFacade != null) {
        try {
            List<Doctor> allDoctors = doctorFacade.findAll();
            totalDoctors = allDoctors.size();

            double totalRating = 0.0;
            int ratedDoctors = 0;

            for (Doctor doctor : allDoctors) {
                if (doctor.getRating() != null && doctor.getRating() > 0) {
                    totalRating += doctor.getRating();
                    ratedDoctors++;
                }
            }

            if (ratedDoctors > 0) {
                avgDoctorRating = totalRating / ratedDoctors;
            }

            Collections.sort(allDoctors, new Comparator<Doctor>() {
                public int compare(Doctor d1, Doctor d2) {
                    Double rating1 = d1.getRating() != null ? d1.getRating() : 0.0;
                    Double rating2 = d2.getRating() != null ? d2.getRating() : 0.0;
                    return rating2.compareTo(rating1);
                }
            });

            topDoctors = allDoctors.subList(0, Math.min(5, allDoctors.size()));

            List<CounterStaff> allStaff = counterStaffFacade.findAll();
            totalStaff = allStaff.size();

            List<CounterStaff> ratedStaff = new ArrayList<CounterStaff>();
            for (CounterStaff s : allStaff) {
                if (s.getRating() != null && s.getRating() > 0.0) {
                    ratedStaff.add(s);
                }
            }

            Collections.sort(ratedStaff, new Comparator<CounterStaff>() {
                public int compare(CounterStaff s1, CounterStaff s2) {
                    Double rating1 = s1.getRating() != null ? s1.getRating() : 0.0;
                    Double rating2 = s2.getRating() != null ? s2.getRating() : 0.0;
                    return rating2.compareTo(rating1);
                }
            });

            topStaff = ratedStaff.subList(0, Math.min(5, ratedStaff.size()));

            List<Appointment> allAppointments = appointmentFacade.findAll();
            totalAppointments = allAppointments.size();

        } catch (Exception e) {
            System.out.println("Error fetching data from EJB: " + e.getMessage());
            e.printStackTrace();
        }
    }
    // If EJB data is not available, use fallback data
    if (topDoctors.isEmpty()) {
        // Create mock doctors for display
        Doctor mockDoc1 = new Doctor();
        mockDoc1.setName("Dr. Sarah Johnson");
        mockDoc1.setSpecialization("Cardiology");
        mockDoc1.setRating(4.8);

        Doctor mockDoc2 = new Doctor();
        mockDoc2.setName("Dr. Michael Chen");
        mockDoc2.setSpecialization("Dermatology");
        mockDoc2.setRating(4.7);

        Doctor mockDoc3 = new Doctor();
        mockDoc3.setName("Dr. Emily Wong");
        mockDoc3.setSpecialization("Pediatrics");
        mockDoc3.setRating(4.6);

        topDoctors.add(mockDoc1);
        topDoctors.add(mockDoc2);
        topDoctors.add(mockDoc3);

        totalDoctors = 12;
        avgDoctorRating = 4.5;
        totalAppointments = 1245;
    }

    if (topStaff.isEmpty()) {
        // Create mock staff for display
        CounterStaff mockStaff1 = new CounterStaff();
        mockStaff1.setName("Alice Wong");
        mockStaff1.setRating(4.5);

        CounterStaff mockStaff2 = new CounterStaff();
        mockStaff2.setName("Bob Miller");
        mockStaff2.setRating(4.3);

        topStaff.add(mockStaff1);
        topStaff.add(mockStaff2);

        totalStaff = 8;
    }

    DecimalFormat df = new DecimalFormat("#.#");
%>

<!DOCTYPE html>
<html lang="en">
    <head>
        <title>Staff Performance Report - APU Medical Center</title>
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
                            <i class="fa fa-star" style="color:white"></i>
                            <span style="color:white">Staff Performance Report</span>
                        </h1>
                        <p class="lead wow fadeInUp" data-wow-delay="0.2s" style="color: whitesmoke">
                            Top rated doctors, counter staff, and performance insights
                        </p>
                        <nav aria-label="breadcrumb" class="wow fadeInUp" data-wow-delay="0.3s">
                            <ol class="breadcrumb" style="background: transparent; margin: 0;">
                                <li class="breadcrumb-item">
                                    <a href="<%= request.getContextPath()%>/ManagerHomepageServlet" style="color: rgba(255,255,255,0.8);">Dashboard</a>
                                </li>
                                <li class="breadcrumb-item">
                                    <a href="<%= request.getContextPath()%>/manager/reports.jsp" style="color: rgba(255,255,255,0.8);">Reports</a>
                                </li>
                                <li class="breadcrumb-item active" style="color: white;">Staff Performance</li>
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
                                <h3><%= totalDoctors%></h3>
                                <p>Total Doctors</p>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-3 col-sm-6">
                        <div class="kpi-card">
                            <div class="kpi-icon" style="background: linear-gradient(45deg, #f41212 0%, #2c2577 100%);">
                                <i class="fa fa-user"></i>
                            </div>
                            <div class="kpi-content">
                                <h3><%= totalStaff%></h3>
                                <p>Counter Staff</p>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-3 col-sm-6">
                        <div class="kpi-card">
                            <div class="kpi-icon" style="background: linear-gradient(45deg, #2c2577 0%, #f41212 100%);">
                                <i class="fa fa-star"></i>
                            </div>
                            <div class="kpi-content">
                                <h3><%= df.format(avgDoctorRating)%></h3>
                                <p>Avg Doctor Rating</p>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-3 col-sm-6">
                        <div class="kpi-card">
                            <div class="kpi-icon" style="background: linear-gradient(45deg, #f41212 0%, #2c2577 100%);">
                                <i class="fa fa-calendar-check-o"></i>
                            </div>
                            <div class="kpi-content">
                                <h3><%= totalAppointments%></h3>
                                <p>Total Appointments</p>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Charts Row -->
                <div class="row charts-row">
                    <!-- Top Doctors Performance Chart -->
                    <div class="col-md-6">
                        <div class="chart-container">
                            <div class="chart-header">
                                <h3><i class="fa fa-star"></i> Top Doctors Performance</h3>
                            </div>
                            <div class="chart-body">
                                <canvas id="doctorsChart"></canvas>
                            </div>
                        </div>
                    </div>

                    <!-- Counter Staff Performance Chart -->
                    <div class="col-md-6">
                        <div class="chart-container">
                            <div class="chart-header">
                                <h3><i class="fa fa-user"></i> Counter Staff Performance</h3>
                            </div>
                            <div class="chart-body">
                                <canvas id="staffChart"></canvas>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Least Performing Charts Row -->
                <div class="row charts-row">
                    <!-- Least Performing Doctors Chart -->
                    <div class="col-md-6">
                        <div class="chart-container">
                            <div class="chart-header">
                                <h3><i class="fa fa-exclamation-triangle" style="color: #ff6b6b;"></i> Least Performing Doctors</h3>
                            </div>
                            <div class="chart-body">
                                <canvas id="leastDoctorsChart"></canvas>
                            </div>
                            <p style="font-size: 0.95em;color: #888; padding-left: 16px;padding-right: 16px;">
                                <i class="fa fa-info-circle" style="color: #667eea"></i> If a doctor's name appears with a rating of 0, it means they have not yet received any customer feedback.
                            </p>
                        </div>
                    </div>
                    <!-- Least Performing Counter Staff Chart -->
                    <div class="col-md-6">
                        <div class="chart-container">
                            <div class="chart-header">
                                <h3><i class="fa fa-exclamation-triangle" style="color: #ff6b6b;"></i> Least Performing Staff</h3>
                            </div>
                            <div class="chart-body">
                                <canvas id="leastStaffChart"></canvas>
                            </div>
                            <p style="font-size: 0.95em;color: #888; padding-left: 16px;padding-right: 16px;">
                                <i class="fa fa-info-circle" style="color: #667eea"></i> If a staff member's name appears with a rating of 0, it means they have not yet received any customer feedback.
                            </p>
                        </div>
                    </div>
                </div>

                <!-- Performance Tables -->
                <div class="row tables-row">
                    <!-- Top Doctors Table -->
                    <div class="col-md-6">
                        <div class="table-container">
                            <div class="table-header">
                                <h3><i class="fa fa-star"></i> Top Doctors</h3>
                            </div>
                            <div class="table-body">
                                <table class="table table-striped performance-table">
                                    <thead>
                                        <tr>
                                            <th>Rank</th>
                                            <th>Doctor</th>
                                            <th>Specialization</th>
                                            <th>Rating</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <%
                                            int rank = 1;
                                            for (Doctor doctor : topDoctors) {
                                        %>
                                        <tr>
                                            <td><%= rank++%></td>
                                            <td><%= doctor.getName() != null ? doctor.getName() : "N/A"%></td>
                                            <td><%= doctor.getSpecialization() != null ? doctor.getSpecialization() : "N/A"%></td>
                                            <td>
                                                <span class="rating-badge">
                                                    <%= doctor.getRating() != null ? df.format(doctor.getRating()) : "0.0"%>/10
                                                </span>
                                            </td>
                                        </tr>
                                        <% } %>
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>

                    <!-- Top Counter Staff Table -->
                    <div class="col-md-6">
                        <div class="table-container">
                            <div class="table-header">
                                <h3><i class="fa fa-user"></i> Top Counter Staffs</h3>
                            </div>
                            <div class="table-body">
                                <table class="table table-striped performance-table">
                                    <thead>
                                        <tr>
                                            <th>Rank</th>
                                            <th>Name</th>
                                            <th>Rating</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <%
                                            rank = 1;
                                            for (CounterStaff staff : topStaff) {
                                        %>
                                        <tr>
                                            <td><%= rank++%></td>
                                            <td><%= staff.getName() != null ? staff.getName() : "N/A"%></td>
                                            <td>
                                                <span class="rating-badge">
                                                    <%= staff.getRating() != null ? df.format(staff.getRating()) : "N/A"%>/10
                                                </span>
                                            </td>
                                        </tr>
                                        <% } %>
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Least Performing Tables -->
                <div class="row tables-row">
                    <!-- Least Performing Doctors Table -->
                    <div class="col-md-6">
                        <div class="table-container">
                            <div class="table-header">
                                <h3><i class="fa fa-exclamation-triangle" style="color: #ff6b6b;"></i> Least Performing Doctors</h3>
                            </div>
                            <div class="table-body">
                                <table class="table table-striped performance-table">
                                    <thead>
                                        <tr>
                                            <th>Rank</th>
                                            <th>Doctor</th>
                                            <th>Specialization</th>
                                            <th>Rating</th>
                                            <th>Status</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <%
                                            // Get least performing doctors (sorted by lowest rating)
                                            List<Doctor> leastDoctors = new ArrayList<Doctor>();

                                            if (doctorFacade != null) {
                                                try {
                                                    List<Doctor> allDoctors = doctorFacade.findAll();

                                                    if (!allDoctors.isEmpty()) {
                                                        // Sort by rating ascending (lowest first)
                                                        Collections.sort(allDoctors, new Comparator<Doctor>() {
                                                            public int compare(Doctor d1, Doctor d2) {
                                                                Double rating1 = d1.getRating() != null ? d1.getRating() : 0.0;
                                                                Double rating2 = d2.getRating() != null ? d2.getRating() : 0.0;
                                                                return rating1.compareTo(rating2);
                                                            }
                                                        });

                                                        leastDoctors = allDoctors.subList(0, Math.min(5, allDoctors.size()));
                                                    }
                                                } catch (Exception e) {
                                                    System.out.println("Error fetching least performing doctors: " + e.getMessage());
                                                }
                                            }

                                            if (leastDoctors.isEmpty()) {
                                        %>
                                        <tr>
                                            <td colspan="5" style="text-align: center; padding: 40px; color: #6c757d;">
                                                <i class="fa fa-info-circle" style="font-size: 24px; margin-bottom: 10px;"></i><br>
                                                <strong>Not enough records to generate report</strong><br>
                                                <small>No doctor performance data available</small>
                                            </td>
                                        </tr>
                                        <%
                                        } else {
                                            rank = 1;
                                            for (Doctor doctor : leastDoctors) {
                                        %>
                                        <tr>
                                            <td><%= rank++%></td>
                                            <td><%= doctor.getName() != null ? doctor.getName() : "N/A"%></td>
                                            <td><%= doctor.getSpecialization() != null ? doctor.getSpecialization() : "N/A"%></td>
                                            <td>
                                                <% if (doctor.getRating() == null || doctor.getRating() == 0.0) { %>
                                                <span class="rating-badge" style="background-color: #6c757d;">No Rating</span>
                                                <% } else {%>
                                                <span class="rating-badge" style="background-color: #ff6b6b;">
                                                    <%= df.format(doctor.getRating())%>/10
                                                </span>
                                                <% } %>
                                            </td>
                                            <td>
                                                <% if (doctor.getRating() == null || doctor.getRating() == 0.0) { %>
                                                <span class="status-badge" style="background-color: #ffc107; color: #212529;">Needs Review</span>
                                                <% } else if (doctor.getRating() < 3.5) { %>
                                                <span class="status-badge" style="background-color: #dc3545;">Poor</span>
                                                <% } else { %>
                                                <span class="status-badge" style="background-color: #fd7e14;">Below Average</span>
                                                <% } %>
                                            </td>
                                        </tr>
                                        <%
                                                }
                                            }
                                        %>
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>

                    <!-- Least Performing Counter Staff Table -->
                    <div class="col-md-6">
                        <div class="table-container">
                            <div class="table-header">
                                <h3><i class="fa fa-exclamation-triangle" style="color: #ff6b6b;"></i> Least Performing Counter Staff</h3>
                            </div>
                            <div class="table-body">
                                <table class="table table-striped performance-table">
                                    <thead>
                                        <tr>
                                            <th>Rank</th>
                                            <th>Name</th>
                                            <th>Rating</th>
                                            <th>Status</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <%
                                            // Get least performing counter staff (sorted by lowest rating)
                                            List<CounterStaff> leastStaff = new ArrayList<CounterStaff>();

                                            if (counterStaffFacade != null) {
                                                try {
                                                    List<CounterStaff> allStaff = counterStaffFacade.findAll();

                                                    if (!allStaff.isEmpty()) {
                                                        // Sort by rating ascending (lowest first)
                                                        Collections.sort(allStaff, new Comparator<CounterStaff>() {
                                                            public int compare(CounterStaff s1, CounterStaff s2) {
                                                                Double rating1 = s1.getRating() != null ? s1.getRating() : 0.0;
                                                                Double rating2 = s2.getRating() != null ? s2.getRating() : 0.0;
                                                                return rating1.compareTo(rating2);
                                                            }
                                                        });

                                                        leastStaff = allStaff.subList(0, Math.min(5, allStaff.size()));
                                                    }
                                                } catch (Exception e) {
                                                    System.out.println("Error fetching least performing staff: " + e.getMessage());
                                                }
                                            }

                                            if (leastStaff.isEmpty()) {
                                        %>
                                        <tr>
                                            <td colspan="4" style="text-align: center; padding: 40px; color: #6c757d;">
                                                <i class="fa fa-info-circle" style="font-size: 24px; margin-bottom: 10px;"></i><br>
                                                <strong>Not enough records to generate report</strong><br>
                                                <small>No counter staff performance data available</small>
                                            </td>
                                        </tr>
                                        <%
                                        } else {
                                            rank = 1;
                                            for (CounterStaff staff : leastStaff) {
                                        %>
                                        <tr>
                                            <td><%= rank++%></td>
                                            <td><%= staff.getName() != null ? staff.getName() : "N/A"%></td>
                                            <td>
                                                <% if (staff.getRating() == null || staff.getRating() == 0.0) { %>
                                                <span class="rating-badge" style="background-color: #6c757d;">No Rating</span>
                                                <% } else {%>
                                                <span class="rating-badge" style="background-color: #ff6b6b;">
                                                    <%= df.format(staff.getRating())%>/10
                                                </span>
                                                <% } %>
                                            </td>
                                            <td>
                                                <% if (staff.getRating() == null || staff.getRating() == 0.0) { %>
                                                <span class="status-badge" style="background-color: #ffc107; color: #212529;">Needs Review</span>
                                                <% } else if (staff.getRating() < 3.5) { %>
                                                <span class="status-badge" style="background-color: #dc3545;">Poor</span>
                                                <% } else { %>
                                                <span class="status-badge" style="background-color: #fd7e14;">Below Average</span>
                                                <% } %>
                                            </td>
                                        </tr>
                                        <%
                                                }
                                            }
                                        %>
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
            let doctorsChart, staffChart, leastDoctorsChart, leastStaffChart;
            $(document).ready(function () {
            initializeCharts();
            });
            function initializeCharts() {
            // Prepare top doctors data
            var topDoctorsData = [
            <% for (int i = 0; i < topDoctors.size(); i++) {
                    Doctor doctor = topDoctors.get(i);
                    if (i > 0) {
                        out.print(",");
                    }
            %>
            {
            name: '<%= doctor.getName() != null ? doctor.getName().replace("'", "\\'") : "N/A"%>',
                    rating: <%= doctor.getRating() != null ? doctor.getRating() : 0.0%>
            }
            <% } %>
            ];
            // Prepare top staff data
            var topStaffData = [
            <% for (int i = 0; i < topStaff.size(); i++) {
                    CounterStaff staff = topStaff.get(i);
                    if (i > 0) {
                        out.print(",");
                    }
            %>
            {
            name: '<%= staff.getName() != null ? staff.getName().replace("'", "\\'") : "N/A"%>',
                    rating: <%= staff.getRating() != null ? staff.getRating() : 4.0%>
            }
            <% }%>
            ];
            // Prepare least performing doctors data
            var leastDoctorsData = [
            <%
                    // Generate JavaScript data for least performing doctors
                    List<Doctor> jsLeastDoctors = new ArrayList<Doctor>();

                    if (doctorFacade != null) {
                        try {
                            List<Doctor> allDoctors = doctorFacade.findAll();
                            if (!allDoctors.isEmpty()) {
                                Collections.sort(allDoctors, new Comparator<Doctor>() {
                                    public int compare(Doctor d1, Doctor d2) {
                                        Double rating1 = d1.getRating() != null ? d1.getRating() : 0.0;
                                        Double rating2 = d2.getRating() != null ? d2.getRating() : 0.0;
                                        return rating1.compareTo(rating2);
                                    }
                                });
                                jsLeastDoctors = allDoctors.subList(0, Math.min(5, allDoctors.size()));
                            }
                        } catch (Exception e) {
                            System.out.println("Error in JS data generation for least doctors: " + e.getMessage());
                        }
                    }

                    for (int i = 0; i < jsLeastDoctors.size(); i++) {
                        Doctor doctor = jsLeastDoctors.get(i);
                        if (i > 0) {
                            out.print(",");
                        }
            %>
            {
            name: '<%= doctor.getName() != null ? doctor.getName().replace("'", "\\'") : "N/A"%>',
                    rating: <%= doctor.getRating() != null ? doctor.getRating() : 0.0%>
            }
            <% } %>
            ];
            // Prepare least performing staff data
            var leastStaffData = [
            <%
                    // Generate JavaScript data for least performing counter staff
                    List<CounterStaff> jsLeastStaff = new ArrayList<CounterStaff>();

                    if (counterStaffFacade != null) {
                        try {
                            List<CounterStaff> allStaff = counterStaffFacade.findAll();
                            if (!allStaff.isEmpty()) {
                                Collections.sort(allStaff, new Comparator<CounterStaff>() {
                                    public int compare(CounterStaff s1, CounterStaff s2) {
                                        Double rating1 = s1.getRating() != null ? s1.getRating() : 0.0;
                                        Double rating2 = s2.getRating() != null ? s2.getRating() : 0.0;
                                        return rating1.compareTo(rating2);
                                    }
                                });
                                jsLeastStaff = allStaff.subList(0, Math.min(5, allStaff.size()));
                            }
                        } catch (Exception e) {
                            System.out.println("Error in JS data generation for least staff: " + e.getMessage());
                        }
                    }

                    for (int i = 0; i < jsLeastStaff.size(); i++) {
                        CounterStaff staff = jsLeastStaff.get(i);
                        if (i > 0) {
                            out.print(",");
                        }
            %>
            {
            name: '<%= staff.getName() != null ? staff.getName().replace("'", "\\'") : "N/A"%>',
                    rating: <%= staff.getRating() != null ? staff.getRating() : 0.0%>
            }
            <% }%>];
            createDoctorsChart(topDoctorsData);
            createStaffChart(topStaffData);
            createLeastDoctorsChart(leastDoctorsData);
            createLeastStaffChart(leastStaffData);
            }

            function createDoctorsChart(data) {
            const ctx = document.getElementById('doctorsChart').getContext('2d');
            doctorsChart = new Chart(ctx, {
            type: 'bar',
                    data: {
                    labels: data.map(function (d) {
                    return d.name;
                    }),
                            datasets: [{
                            label: 'Rating (out of 10)',
                                    data: data.map(function (d) {
                                    return d.rating;
                                    }),
                                    backgroundColor: 'rgba(244, 18, 18, 0.8)',
                                    borderColor: 'rgba(244, 18, 18, 1)',
                                    borderWidth: 2,
                                    borderRadius: 4
                            }]
                    },
                    options: {
                    responsive: true,
                            maintainAspectRatio: false,
                            plugins: {
                            legend: {
                            display: true,
                                    position: 'top'
                            }
                            },
                            scales: {
                            y: {
                            beginAtZero: true,
                                    max: 10,
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
            }

            function createStaffChart(data) {
            const ctx = document.getElementById('staffChart').getContext('2d');
            staffChart = new Chart(ctx, {
            type: 'bar',
                    data: {
                    labels: data.map(function (d) {
                    return d.name;
                    }),
                            datasets: [{
                            label: 'Rating (out of 10)',
                                    data: data.map(function (d) {
                                    return d.rating;
                                    }),
                                    backgroundColor: 'rgba(44, 37, 119, 0.8)',
                                    borderColor: 'rgba(44, 37, 119, 1)',
                                    borderWidth: 2,
                                    borderRadius: 4
                            }]
                    },
                    options: {
                    responsive: true,
                            maintainAspectRatio: false,
                            plugins: {
                            legend: {
                            display: true,
                                    position: 'top'
                            }
                            },
                            scales: {
                            y: {
                            beginAtZero: true,
                                    max: 10,
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
            }

            function createLeastDoctorsChart(data) {
            const ctx = document.getElementById('leastDoctorsChart').getContext('2d');
            if (data.length === 0) {
            // Display "No Data" message
            ctx.font = '16px Arial';
            ctx.fillStyle = '#6c757d';
            ctx.textAlign = 'center';
            ctx.fillText('Not enough records to generate chart', ctx.canvas.width / 2, ctx.canvas.height / 2);
            return;
            }

            leastDoctorsChart = new Chart(ctx, {
            type: 'bar',
                    data: {
                    labels: data.map(function (d) {
                    return d.name;
                    }),
                            datasets: [{
                            label: 'Rating (out of 10)',
                                    data: data.map(function (d) {
                                    return d.rating;
                                    }),
                                    backgroundColor: 'rgba(255, 107, 107, 0.8)',
                                    borderColor: 'rgba(220, 53, 69, 1)',
                                    borderWidth: 2,
                                    borderRadius: 4
                            }]
                    },
                    options: {
                    responsive: true,
                            maintainAspectRatio: false,
                            plugins: {
                            legend: {
                            display: true,
                                    position: 'top'
                            }
                            },
                            scales: {
                            y: {
                            beginAtZero: true,
                                    max: 10,
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
            }

            function createLeastStaffChart(data) {
            const ctx = document.getElementById('leastStaffChart').getContext('2d');
            if (data.length === 0) {
            // Display "No Data" message
            ctx.font = '16px Arial';
            ctx.fillStyle = '#6c757d';
            ctx.textAlign = 'center';
            ctx.fillText('Not enough records to generate chart', ctx.canvas.width / 2, ctx.canvas.height / 2);
            return;
            }

            leastStaffChart = new Chart(ctx, {
            type: 'bar',
                    data: {
                    labels: data.map(function (d) {
                    return d.name;
                    }),
                            datasets: [{
                            label: 'Rating (out of 10)',
                                    data: data.map(function (d) {
                                    return d.rating;
                                    }),
                                    backgroundColor: 'rgba(255, 193, 7, 0.8)',
                                    borderColor: 'rgba(253, 126, 20, 1)',
                                    borderWidth: 2,
                                    borderRadius: 4
                            }]
                    },
                    options: {
                    responsive: true,
                            maintainAspectRatio: false,
                            plugins: {
                            legend: {
                            display: true,
                                    position: 'top'
                            }
                            },
                            scales: {
                            y: {
                            beginAtZero: true,
                                    max: 10,
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
            pdf.text('Staff Performance Report', 20, currentY);
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
            pdf.text('Performance Summary', 20, currentY);
            currentY += 10;
            pdf.setFontSize(11);
            pdf.setTextColor(0, 0, 0);
            pdf.text('Total Doctors: <%= totalDoctors%>', 20, currentY);
            pdf.text('Counter Staff: <%= totalStaff%>', 70, currentY);
            currentY += 7;
            pdf.text('Average Doctor Rating: <%= df.format(avgDoctorRating)%>/10', 20, currentY);
            pdf.text('Total Appointments: <%= totalAppointments%>', 70, currentY);
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

            // Function to add table container to PDF
            function addTableToPDF(tableContainerSelector, title, callback) {
            const tableContainer = document.querySelector(tableContainerSelector);
            if (!tableContainer) {
            console.log('Table container not found:', tableContainerSelector);
            callback();
            return;
            }

            html2canvas(tableContainer, {
            scale: 1.5,
                    useCORS: true,
                    logging: false,
                    backgroundColor: '#ffffff'
            }).then(function (tableCanvas) {
            const tableImg = tableCanvas.toDataURL('image/png');
            const imgWidth = 170;
            const imgHeight = (tableCanvas.height * imgWidth) / tableCanvas.width;
            // Check if we need a new page
            if (currentY + imgHeight + 20 > pageHeight - 20) {
            pdf.addPage();
            currentY = 20;
            }

            // Add table title
            pdf.setFontSize(14);
            pdf.setTextColor(44, 37, 119);
            pdf.text(title, 20, currentY);
            currentY += 10;
            // Add table image
            pdf.addImage(tableImg, 'PNG', 20, currentY, imgWidth, imgHeight);
            currentY += imgHeight + 15;
            callback();
            }).catch(function (error) {
            console.error('Error capturing table:', error);
            callback();
            });
            }

            // Sequential processing of charts and tables
            addChartToPDF('doctorsChart', 'Top Doctors Performance Chart', function() {
            addChartToPDF('staffChart', 'Counter Staff Performance Chart', function() {
            addChartToPDF('leastDoctorsChart', 'Least Performing Doctors Chart', function() {
            addChartToPDF('leastStaffChart', 'Least Performing Staff Chart', function() {
            // Add a new page for tables
            pdf.addPage();
            currentY = 20;
            // Add tables section header
            pdf.setFontSize(18);
            pdf.setTextColor(44, 37, 119);
            pdf.text('Performance Tables', 20, currentY);
            currentY += 15;
            // Get all table containers and capture them directly
            const tableContainers = document.querySelectorAll('.table-container');
            console.log('Found table containers:', tableContainers.length);
            if (tableContainers.length >= 4) {
            // Capture each table container by direct reference
            function captureTableByIndex(index, title, callback) {
            if (index >= tableContainers.length) {
            callback();
            return;
            }

            const tableContainer = tableContainers[index];
            html2canvas(tableContainer, {
            scale: 1.5,
                    useCORS: true,
                    logging: false,
                    backgroundColor: '#ffffff'
            }).then(function (tableCanvas) {
            const tableImg = tableCanvas.toDataURL('image/png');
            const imgWidth = 170;
            const imgHeight = (tableCanvas.height * imgWidth) / tableCanvas.width;
            // Check if we need a new page
            if (currentY + imgHeight + 20 > pageHeight - 20) {
            pdf.addPage();
            currentY = 20;
            }

            // Add table title
            pdf.setFontSize(14);
            pdf.setTextColor(44, 37, 119);
            pdf.text(title, 20, currentY);
            currentY += 10;
            // Add table image
            pdf.addImage(tableImg, 'PNG', 20, currentY, imgWidth, imgHeight);
            currentY += imgHeight + 15;
            callback();
            }).catch(function (error) {
            console.error('Error capturing table:', error);
            callback();
            });
            }

            // Capture tables sequentially
            captureTableByIndex(0, 'Top Doctors', function() {
            captureTableByIndex(1, 'Top Counter Staff', function() {
            captureTableByIndex(2, 'Least Performing Doctors', function() {
            captureTableByIndex(3, 'Least Performing Counter Staff', function() {
            // Remove loading message and save PDF
            document.body.removeChild(loadingDiv);
            pdf.save('Staff_Performance_Report_' + new Date().toISOString().split('T')[0] + '.pdf');
            });
            });
            });
            });
            } else {
            // If tables not found, just finish without tables
            console.log('Not all tables found, finishing PDF without tables');
            document.body.removeChild(loadingDiv);
            pdf.save('Staff_Performance_Report_' + new Date().toISOString().split('T')[0] + '.pdf');
            }
            });
            });
            });
            });
            }
        </script>
    </body>
</html>