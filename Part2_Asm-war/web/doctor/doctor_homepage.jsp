<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="model.Customer" %>
<%@ page import="model.CounterStaff" %>
<%@ page import="model.Doctor" %>
<%@ page import="model.Appointment" %>
<%@ page import="model.Payment" %>
<%@ page import="model.Feedback" %>
<%@ page import="model.Treatment" %>
<%@ page import="java.text.DecimalFormat" %>

<%
    // Check if doctor is logged in
    Doctor loggedInDoctor = (Doctor) session.getAttribute("doctor");

    if (loggedInDoctor == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    } else {
        System.out.println("Doctor " + loggedInDoctor.getName() + " logged in successfully!");
    }

    // Check if we need to load dashboard data
    if (request.getAttribute("totalPatients") == null) {
        // Redirect to servlet to load dashboard data
        response.sendRedirect(request.getContextPath() + "/DoctorHomepageServlet?action=dashboard");
        return;
    }

    // Retrieve dashboard data from request attributes (loaded by servlet)
    List<Appointment> myTodayAppointments = (List<Appointment>) request.getAttribute("myTodayAppointments");
    List<Appointment> myPendingAppointments = (List<Appointment>) request.getAttribute("myPendingAppointments");
    List<Appointment> myRecentAppointments = (List<Appointment>) request.getAttribute("myRecentAppointments");
    List<Treatment> myTreatments = (List<Treatment>) request.getAttribute("myTreatments");
    List<Feedback> myRecentFeedbacks = (List<Feedback>) request.getAttribute("myRecentFeedbacks");

    // Dashboard statistics
    Integer totalPatients = (Integer) request.getAttribute("totalPatients");
    Integer myTotalAppointments = (Integer) request.getAttribute("myTotalAppointments");
    Integer myApprovedAppointments = (Integer) request.getAttribute("myApprovedAppointments");
    Integer myCompletedAppointments = (Integer) request.getAttribute("myCompletedAppointments");
    Integer treatmentsManaged = (Integer) request.getAttribute("treatmentsManaged");
    Double totalChargesIssued = (Double) request.getAttribute("totalChargesIssued");

    // Default values if null
    if (totalPatients == null) {
        totalPatients = 0;
    }
    if (myTotalAppointments == null) {
        myTotalAppointments = 0;
    }
    if (myApprovedAppointments == null) {
        myApprovedAppointments = 0;
    }
    if (myCompletedAppointments == null) {
        myCompletedAppointments = 0;
    }
    if (treatmentsManaged == null) {
        treatmentsManaged = 0;
    }
    if (totalChargesIssued == null) {
        totalChargesIssued = 0.0;
    }

    DecimalFormat currencyFormat = new DecimalFormat("#,##0.00");
%>

<!DOCTYPE html>
<html lang="en">
    <head>
        <title>Doctor Homepage - APU Medical Center</title>
        <%@ include file="/includes/head.jsp" %>
        <link rel="stylesheet" href="<%= contextPath%>/css/staff.css">

    </head>

    <body id="top" data-spy="scroll" data-target=".navbar-collapse" data-offset="50">
        <%@ include file="/includes/preloader.jsp" %>
        <%@ include file="/includes/header.jsp" %>
        <%@ include file="/includes/navbar.jsp" %>
        <!-- DASHBOARD STATISTICS -->
        <section id="dashboard-stats" class="dashboard-stats counter-staff-header">
            <div class="container">
                <div class="row">
                    <div class="col-md-12">
                        <div class="section-title wow fadeInUp" data-wow-delay="0.1s">
                            <h2 style="color: white;">Today's Overview</h2>
                        </div>
                    </div>
                </div>
                <div class="row">
                    <div class="col-md-2 col-sm-6">
                        <div class="stat-card-wrapper">
                            <div class="stat-card counter-staff wow fadeInUp" data-wow-delay="0.2s">
                                <span class="stat-number"><%= totalPatients%></span>
                                <span class="stat-label">Total Patients</span>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-2 col-sm-6">
                        <div class="stat-card-wrapper">
                            <div class="stat-card counter-staff wow fadeInUp" data-wow-delay="0.3s">
                                <span class="stat-number"><%= myTotalAppointments%></span>
                                <span class="stat-label">My Appointments</span>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-2 col-sm-6">
                        <div class="stat-card-wrapper">
                            <div class="stat-card counter-staff wow fadeInUp" data-wow-delay="0.4s">
                                <span class="stat-number">
                                    <%= myApprovedAppointments%>
                                </span>
                                <span class="stat-label">Approved</span>
                                <% if (myApprovedAppointments > 0) { %>
                                <span class="urgent-indicator new">Ready</span>
                                <% }%>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-2 col-sm-6">
                        <div class="stat-card-wrapper">
                            <div class="stat-card counter-staff wow fadeInUp" data-wow-delay="0.5s">
                                <span class="stat-number">
                                    <%= (myTodayAppointments != null ? myTodayAppointments.size() : 0)%>
                                </span>
                                <span class="stat-label">Today's Tasks</span>
                                <% if (myTodayAppointments != null && myTodayAppointments.size() > 0) { %>
                                <span class="urgent-indicator">!</span>
                                <% }%>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-2 col-sm-6">
                        <div class="stat-card-wrapper">
                            <div class="stat-card counter-staff wow fadeInUp" data-wow-delay="0.6s">
                                <span class="stat-number">
                                    <%= treatmentsManaged%>
                                </span>
                                <span class="stat-label">Treatments Managed</span>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-2 col-sm-6">
                        <div class="stat-card-wrapper">
                            <div class="stat-card counter-staff wow fadeInUp" data-wow-delay="0.7s">
                                <span class="stat-number stat-payment">RM<%= currencyFormat.format(totalChargesIssued)%></span>
                                <span class="stat-label">Charges Issued</span>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </section>

        <!-- QUICK ACTIONS -->
        <section class="quick-actions">
            <div class="container">
                <div class="row">
                    <div class="col-md-12">
                        <div class="section-title wow fadeInUp" data-wow-delay="0.1s">
                            <h2>Quick Actions</h2>
                        </div>
                    </div>
                </div>
                <div class="row">
                    <!-- My Tasks -->
                    <div class="col-md-3 col-sm-6">
                        <a href="<%= request.getContextPath()%>/DoctorServlet?action=viewMyTasks" style="text-decoration: none;">
                            <div class="action-card wow fadeInUp" data-wow-delay="0.2s">
                                <div class="action-icon counter-staff">
                                    <i class="fa fa-tasks"></i>
                                </div>
                                <div class="action-title">My Tasks</div>
                                <div class="action-desc">View and check approved appointments assigned to me</div>
                            </div>
                        </a>
                    </div>

                    <!-- Manage Treatment -->
                    <div class="col-md-3 col-sm-6">
                        <a href="<%= request.getContextPath()%>/TreatmentServlet?action=manage" style="text-decoration: none;">
                            <div class="action-card wow fadeInUp" data-wow-delay="0.3s">
                                <div class="action-icon counter-staff">
                                    <i class="fa fa-stethoscope"></i>
                                </div>
                                <div class="action-title">Manage Treatment</div>
                                <div class="action-desc">CRUD treatments, descriptions, charges, and prescriptions</div>
                            </div>
                        </a>
                    </div>

                    <!-- Appointment Histories -->
                    <div class="col-md-3 col-sm-6">
                        <a href="<%= request.getContextPath()%>/DoctorServlet?action=appointmentHistories" style="text-decoration: none;">
                            <div class="action-card wow fadeInUp" data-wow-delay="0.4s">
                                <div class="action-icon counter-staff">
                                    <i class="fa fa-history"></i>
                                </div>
                                <div class="action-title">Appointment Histories</div>
                                <div class="action-desc">Check completed appointments, charges and ratings</div>
                            </div>
                        </a>
                    </div>

                    <!-- Issue Payment -->
                    <div class="col-md-3 col-sm-6">
                        <a href="<%= request.getContextPath()%>/DoctorServlet?action=issuePayment" style="text-decoration: none;">
                            <div class="action-card wow fadeInUp" data-wow-delay="0.5s">
                                <div class="action-icon counter-staff">
                                    <i class="fa fa-calculator"></i>
                                </div>
                                <div class="action-title">Issue Payment</div>
                                <div class="action-desc">Enter charges, provide feedback, generate medical certificates</div>
                            </div>
                        </a>
                    </div>
                </div>

                <!-- Second Row of Actions -->
                <div class="row" style="margin-top: 20px;">
                    <!-- My Rating -->
                    <div class="col-md-3 col-sm-6">
                        <a href="<%= request.getContextPath()%>/DoctorServlet?action=viewMyRatings" style="text-decoration: none;">
                            <div class="action-card wow fadeInUp" data-wow-delay="0.6s">
                                <div class="action-icon counter-staff">
                                    <i class="fa fa-star"></i>
                                </div>
                                <div class="action-title">My Rating</div>
                                <div class="action-desc">View patient feedback and ratings received</div>
                            </div>
                        </a>
                    </div>

                    <!-- My Profile -->
                    <div class="col-md-3 col-sm-6">
                        <a href="<%= request.getContextPath()%>/profile.jsp" style="text-decoration: none;">
                            <div class="action-card wow fadeInUp" data-wow-delay="0.7s">
                                <div class="action-icon counter-staff">
                                    <i class="fa fa-user"></i>
                                </div>
                                <div class="action-title">Profile</div>
                                <div class="action-desc">Update personal information and settings</div>
                            </div>
                        </a>
                    </div>

                    <!-- Patient Records -->
                    <div class="col-md-3 col-sm-6">
                        <a href="<%= request.getContextPath()%>/DoctorServlet?action=patientRecords" style="text-decoration: none;">
                            <div class="action-card wow fadeInUp" data-wow-delay="0.8s">
                                <div class="action-icon counter-staff">
                                    <i class="fa fa-medkit"></i>                                </div>
                                <div class="action-title">Patient Records</div>
                                <div class="action-desc">Access patient medical histories and records</div>
                            </div>
                        </a>
                    </div>

                    <!-- Schedule Management -->
                    <div class="col-md-3 col-sm-6">
                        <a href="<%= request.getContextPath()%>/ScheduleServlet?action=manage" style="text-decoration: none;">
                            <div class="action-card wow fadeInUp" data-wow-delay="0.9s">
                                <div class="action-icon counter-staff">
                                    <i class="fa fa-calendar"></i>
                                </div>
                                <div class="action-title">My Schedule</div>
                                <div class="action-desc">Manage availability and working hours</div>
                            </div>
                        </a>
                    </div>
                </div>
            </div>
            <!-- RECENT ACTIVITIES -->
            <section class="recent-section">
                <div class="container">
                    <div class="row">
                        <!-- Priority Tasks -->
                        <div class="col-md-6">
                            <div class="section-header">
                                <h3><i class="fa fa-exclamation-triangle" style="color: #dc3545;"></i> Priority Tasks</h3>
                            </div>

                            <!-- Today's Appointments -->
                            <% if (myTodayAppointments != null && myTodayAppointments.size() > 0) {%>
                            <div class="priority-card wow fadeInRight animated" data-wow-delay="0.2s" style="margin-bottom: 15px; padding: 15px; border-radius: 8px; visibility: visible; animation-duration: 0.2s; animation-name: fadeInLeft">
                                <div class="row">
                                    <div class="col-sm-8">
                                        <h5 style="margin: 0; color: #dc3545;">
                                            <i class="fa fa-calendar-check-o"></i> Today's Appointments
                                        </h5>
                                        <p style="margin: 5px 0; color: #666;">
                                            <%= myTodayAppointments.size()%> appointments scheduled for today
                                        </p>
                                    </div>
                                    <div class="col-sm-4 text-right">
                                        <a href="<%= request.getContextPath()%>/DoctorServlet?action=viewMyTasks&filter=today" 
                                           class="btn btn-sm btn-danger">
                                            <i class="fa fa-eye"></i> View
                                        </a>
                                    </div>
                                </div>
                            </div>
                            <% } %>

                            <!-- Approved Appointments -->
                            <% if (myApprovedAppointments > 0) {%>
                            <div class="priority-card wow fadeInRight animated" data-wow-delay="0.4s" style="margin-bottom: 15px; padding: 15px; border-radius: 8px; visibility: visible; animation-duration: 0.4s; animation-name: fadeInLeft">
                                <div class="row">
                                    <div class="col-sm-8">
                                        <h5 style="margin: 0; color: #ffc107;">
                                            <i class="fa fa-user-md"></i> Approved Appointments
                                        </h5>
                                        <p style="margin: 5px 0; color: #666;">
                                            <%= myApprovedAppointments%> appointments ready for consultation
                                        </p>
                                    </div>
                                    <div class="col-sm-4 text-right">
                                        <a href="<%= request.getContextPath()%>/DoctorServlet?action=viewMyTasks&filter=approved"
                                           class="btn btn-sm btn-warning">
                                            <i class="fa fa-stethoscope"></i> Start
                                        </a>
                                    </div>
                                </div>
                            </div>
                            <% } %>

                            <!-- Pending Charges -->
                            <%
                                // Count appointments that need payment processing
                                int pendingCharges = 0;
                                if (myRecentAppointments != null) {
                                    for (Appointment apt : myRecentAppointments) {
                                        if ("completed".equals(apt.getStatus()) && apt.getReceipt() == null) {
                                            pendingCharges++;
                                    }
                                }
                            }
                            if (pendingCharges > 0) {%>
                            <div class="priority-card wow fadeInRight animated" data-wow-delay="0.6s" style="margin-bottom: 15px; padding: 15px; border-radius: 8px; visibility: visible; animation-duration: 0.6s; animation-name: fadeInLeft">
                                <div class="row">
                                    <div class="col-sm-8">
                                        <h5 style="margin: 0; color: #28a745;">
                                            <i class="fa fa-calculator"></i> Pending Charges
                                        </h5>
                                        <p style="margin: 5px 0; color: #666;">
                                            <%= pendingCharges%> completed appointments need payment processing
                                        </p>
                                    </div>
                                    <div class="col-sm-4 text-right">
                                        <a href="<%= request.getContextPath()%>/DoctorServlet?action=issuePayment" 
                                           class="btn btn-sm btn-success">
                                            <i class="fa fa-money"></i> Process
                                        </a>
                                    </div>
                                </div>
                            </div>
                            <% } %>

                            <!-- If no priority tasks -->
                            <% if ((myTodayAppointments == null || myTodayAppointments.size() == 0) && myApprovedAppointments == 0 && pendingCharges == 0) { %>
                            <div class="alert alert-success">
                                <i class="fa fa-check-circle"></i>
                                Great! No urgent tasks at the moment.
                            </div>
                            <% } %>
                        </div>

                        <!-- Recent Activities -->
                        <div class="col-md-6">
                            <div class="section-header">
                                <h3><i class="fa fa-clock-o"></i> Recent Activities</h3>
                            </div>

                            <%
                                if (myRecentAppointments != null && !myRecentAppointments.isEmpty()) {
                                    int maxAppointments = Math.min(5, myRecentAppointments.size());
                                    for (int i = 0; i < maxAppointments; i++) {
                                        Appointment apt = myRecentAppointments.get(i);
                                        if (apt != null) {
                                            String statusClass = "status-pending";
                                            String statusText = "Pending";
                                            String actionText = "";

                                            if (apt.getStatus() != null) {
                                                String status = apt.getStatus().toLowerCase();
                                                if ("approved".equals(status)) {
                                                    statusClass = "status-confirmed";
                                                    statusText = "Approved";
                                                    actionText = "Ready for consultation";
                                                } else if ("completed".equals(status)) {
                                                    statusClass = "status-completed";
                                                    statusText = "Completed";
                                                    actionText = "Treatment finished";
                                                } else if ("in_progress".equals(status)) {
                                                    statusClass = "status-progress";
                                                    statusText = "In Progress";
                                                    actionText = "Consultation ongoing";
                                                } else if ("cancelled".equals(status)) {
                                                    statusClass = "status-cancelled";
                                                    statusText = "Cancelled";
                                                    actionText = "By patient";
                                                } else {
                                                    actionText = "Awaiting assignment";
                                                }
                                            }
                            %>
                            <div class="appointment-card wow fadeInRight" data-wow-delay="<%= 0.2 + (i * 0.1)%>s">
                                <div class="row">
                                    <div class="col-sm-8">
                                        <h5 style="margin: 0; color: #333;">
                                            <%= apt.getCustomer() != null ? apt.getCustomer().getName() : "N/A"%>
                                        </h5>
                                        <p style="margin: 5px 0; color: #666;">
                                            <%= apt.getTreatment() != null ? apt.getTreatment().getName() : "N/A"%>
                                        </p>
                                        <small style="color: #999;">
                                            <%
                                                java.text.SimpleDateFormat sdf = new java.text.SimpleDateFormat("EEE MMM dd yyyy");
                                            %>
                                            <%= apt.getAppointmentDate() != null ? sdf.format(apt.getAppointmentDate()) : "N/A"%>
                                            <% if (!actionText.isEmpty()) {%>
                                            - <%= actionText%>
                                            <% }%>
                                        </small>
                                    </div>
                                    <div class="col-sm-4 text-right">
                                        <span class="appointment-status <%= statusClass%>">
                                            <%= statusText%>
                                        </span>
                                    </div>
                                </div>
                            </div>
                            <%
                                    }
                                }
                            } else {
                            %>
                            <div class="alert alert-info">
                                <i class="fa fa-info-circle"></i>
                                No recent activities to display.
                            </div>
                            <% }%>

                            <div class="text-center" style="margin-top: 20px;">
                                <a href="<%= request.getContextPath()%>/DoctorServlet?action=viewMyTasks" class="btn btn-success">
                                    <i class="fa fa-calendar"></i> View All My Tasks
                                </a>
                            </div>
                        </div>
                    </div>

                    <!-- Performance Summary Row -->
                    <div class="row" style="margin-top: 30px;">
                        <div class="col-md-12">
                            <div class="section-header">
                                <h3><i class="fa fa-bar-chart"></i> My Performance</h3>
                            </div>
                        </div>
                    </div>

                    <div class="row performance-row">
                        <!-- My Rating -->
                        <div class="col-md-3 col-sm-6">
                            <div class="staff-card wow fadeInUp" data-wow-delay="0.2s">
                                <div class="text-center">
                                    <h4 style="margin: 0; color: #333;">
                                        <i class="fa fa-star" style="color: #ffc107;"></i> My Rating
                                    </h4>
                                    <p style="margin: 10px 0; font-size: 1.5em; color: #28a745; font-weight: bold;">
                                        <% if (loggedInDoctor.getRating() != null && loggedInDoctor.getRating() > 0) {%>
                                        <%= String.format("%.1f", loggedInDoctor.getRating())%>/10
                                        <% } else { %>
                                        Not rated yet
                                        <% }%>
                                    </p>
                                </div>
                            </div>
                        </div>

                        <!-- Today's Appointments -->
                        <div class="col-md-3 col-sm-6">
                            <div class="staff-card wow fadeInUp" data-wow-delay="0.3s">
                                <div class="text-center">
                                    <h4 style="margin: 0; color: #333;">
                                        <i class="fa fa-calendar-check-o"></i> Today's Tasks
                                    </h4>
                                    <p style="margin: 10px 0; font-size: 1.5em; color: #17a2b8; font-weight: bold;">
                                        <%= (myTodayAppointments != null ? myTodayAppointments.size() : 0)%>
                                    </p>
                                    <small style="color: #666;">Appointments today</small>
                                </div>
                            </div>
                        </div>

                        <!-- Patient Feedback -->
                        <div class="col-md-3 col-sm-6">
                            <div class="staff-card wow fadeInUp" data-wow-delay="0.4s">
                                <div class="text-center">
                                    <h4 style="margin: 0; color: #333;">
                                        <i class="fa fa-comments"></i> Feedback
                                    </h4>
                                    <p style="margin: 10px 0; font-size: 1.5em; color: #6c757d; font-weight: bold;">
                                        <%= (myRecentFeedbacks != null ? myRecentFeedbacks.size() : 0)%>
                                    </p>
                                    <small style="color: #666;">Recent reviews</small>
                                </div>
                            </div>
                        </div>

                        <!-- Quick Stats -->
                        <div class="col-md-3 col-sm-6">
                            <div class="staff-card wow fadeInUp" data-wow-delay="0.5s">
                                <div class="text-center">
                                    <h4 style="margin: 0; color: #333;">
                                        <i class="fa fa-check-square-o"></i> Completed
                                    </h4>
                                    <p style="margin: 10px 0; font-size: 1.5em; color: #28a745; font-weight: bold;">
                                        <%= myCompletedAppointments%>
                                    </p>
                                    <small style="color: #666;">This month</small>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </section>

            <%@ include file="/includes/footer.jsp" %>
            <%@ include file="/includes/scripts.jsp" %>
            <script>
                // Doctor specific JavaScript
                $(document).ready(function () {
                    // Initialize dashboard
                    console.log('Doctor Dashboard loaded successfully');

                    // Add click tracking for dashboard actions
                    $('.action-card').click(function () {
                        const actionTitle = $(this).find('.action-title').text();
                        console.log('Doctor action clicked:', actionTitle);
                    });

                    // Auto-refresh priority indicators every 5 minutes
                    setInterval(function () {
                        // You can implement AJAX refresh here if needed
                        console.log('Checking for updates...');
                    }, 300000); // 5 minutes

                    // Highlight urgent tasks
                    $('.urgent-indicator').each(function () {
                        $(this).parent().parent().parent().addClass('priority-highlight');
                    });
                });

                // Helper function to show notifications
                function showNotification(message, type = 'info') {
                    const alertClass = type === 'success' ? 'alert-success' :
                            type === 'warning' ? 'alert-warning' :
                            type === 'error' ? 'alert-danger' : 'alert-info';

                    const notification = $(`
                        <div class="alert ${alertClass} alert-dismissible" style="position: fixed; top: 80px; right: 20px; z-index: 1000; min-width: 300px;">
                            <button type="button" class="close" data-dismiss="alert">&times;</button>
                ${message}
                        </div>
                    `);

                    $('body').append(notification);

                    // Auto-hide after 5 seconds
                    setTimeout(function () {
                        notification.fadeOut();
                    }, 5000);
                }
            </script>
    </body>
</html>
