<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="model.Customer" %>
<%@ page import="model.CounterStaff" %>
<%@ page import="model.Doctor" %>
<%@ page import="model.Appointment" %>
<%@ page import="model.Payment" %>
<%@ page import="model.Feedback" %>
<%@ page import="java.text.DecimalFormat" %>

<%
    // Check if counter staff is logged in
    CounterStaff loggedInStaff = (CounterStaff) session.getAttribute("staff");

    if (loggedInStaff == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    } else {
        System.out.println("Counter Staff " + loggedInStaff.getName() + " logged in successfully!");
    }

    // Check if we need to load dashboard data
    if (request.getAttribute("totalCustomers") == null) {
        // Redirect to servlet to load dashboard data
        response.sendRedirect(request.getContextPath() + "/CounterStaffServletJam?action=dashboard");
        return;
    }

    // Retrieve dashboard data from request attributes (loaded by servlet)
    List<Customer> recentCustomers = (List<Customer>) request.getAttribute("recentCustomers");
    List<Appointment> todayAppointments = (List<Appointment>) request.getAttribute("todayAppointments");
    List<Appointment> recentAppointments = (List<Appointment>) request.getAttribute("recentAppointments");
    List<Payment> pendingPayments = (List<Payment>) request.getAttribute("pendingPayments");
    List<Feedback> recentFeedbacks = (List<Feedback>) request.getAttribute("recentFeedbacks");

    // Dashboard statistics
    Integer totalCustomers = (Integer) request.getAttribute("totalCustomers");
    Integer totalAppointments = (Integer) request.getAttribute("totalAppointments");
    Integer pendingAppointmentCount = (Integer) request.getAttribute("pendingAppointmentCount");
    Integer approvedAppointments = (Integer) request.getAttribute("approvedAppointments");
    Integer overdueAppointments = (Integer) request.getAttribute("overdueAppointments");
    Integer completedAppointments = (Integer) request.getAttribute("completedAppointments");
    Integer pendingPaymentCount = (Integer) request.getAttribute("pendingPaymentCount");
    Double todayPayment = (Double) request.getAttribute("todayPayment");

    // Default values if null
    if (totalCustomers == null) {
        totalCustomers = 0;
    }
    if (totalAppointments == null) {
        totalAppointments = 0;
    }
    if (pendingAppointmentCount == null) {
        pendingAppointmentCount = 0;
    }
    if (approvedAppointments == null) {
        approvedAppointments = 0;
    }
    if (overdueAppointments == null) {
        overdueAppointments = 0;
    }
    if (completedAppointments == null) {
        completedAppointments = 0;
    }
    if (pendingPaymentCount == null) {
        pendingPaymentCount = 0;
    }
    if (todayPayment == null) {
        todayPayment = 0.0;
    }

    DecimalFormat currencyFormat = new DecimalFormat("#,##0.00");
%>

<!DOCTYPE html>
<html lang="en">
    <head>
        <title>Counter Staff Homepage - APU Medical Center</title>
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
                                <span class="stat-number"><%= totalCustomers%></span>
                                <span class="stat-label">Total Customers</span>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-2 col-sm-6">
                        <div class="stat-card-wrapper">
                            <div class="stat-card counter-staff wow fadeInUp" data-wow-delay="0.3s">
                                <span class="stat-number"><%= totalAppointments%></span>
                                <span class="stat-label">All Appointments</span>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-2 col-sm-6">
                        <div class="stat-card-wrapper">
                            <div class="stat-card counter-staff wow fadeInUp" data-wow-delay="0.4s">
                                <span class="stat-number">
                                    <%= pendingAppointmentCount%>
                                </span>
                                <span class="stat-label">Pending</span>
                                <% if (pendingAppointmentCount > 0) { %>
                                <span class="urgent-indicator new">New</span>
                                <% }%>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-2 col-sm-6">
                        <div class="stat-card-wrapper">
                            <div class="stat-card counter-staff wow fadeInUp" data-wow-delay="0.5s">
                                <span class="stat-number">
                                    <%= overdueAppointments%>
                                </span>
                                <span class="stat-label">Overdue</span>
                                <% if (overdueAppointments > 0) { %>
                                <span class="urgent-indicator">!</span>
                                <% }%>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-2 col-sm-6">
                        <div class="stat-card-wrapper">
                            <div class="stat-card counter-staff wow fadeInUp" data-wow-delay="0.6s">
                                <span class="stat-number">
                                    <%= pendingPaymentCount%>
                                </span>
                                <span class="stat-label">Pending Payments</span>
                                <% if (pendingPaymentCount > 0) { %>
                                <span class="urgent-indicator payment">!</span>
                                <% }%>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-2 col-sm-6">
                        <div class="stat-card-wrapper">
                            <div class="stat-card counter-staff wow fadeInUp" data-wow-delay="0.7s">
                                <span class="stat-number stat-payment">RM<%= currencyFormat.format(todayPayment)%></span>
                                <span class="stat-label">Payment Collected</span>
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
                    <!-- Customer Management -->
                    <div class="col-md-3 col-sm-6">
                        <a href="<%= request.getContextPath()%>/CustomerServlet?action=viewAll" style="text-decoration: none;">
                            <div class="action-card wow fadeInUp" data-wow-delay="0.2s">
                                <div class="action-icon counter-staff">
                                    <i class="fa fa-users"></i>
                                </div>
                                <div class="action-title">Manage Customers</div>
                                <div class="action-desc">Create, edit, delete and search customer records</div>
                            </div>
                        </a>
                    </div>

                    <!-- Appointment Booking -->
                    <div class="col-md-3 col-sm-6">
                        <a href="<%= request.getContextPath()%>/AppointmentServlet?action=book" style="text-decoration: none;">
                            <div class="action-card wow fadeInUp" data-wow-delay="0.3s">
                                <div class="action-icon counter-staff">
                                    <i class="fa fa-calendar-plus-o"></i>
                                </div>
                                <div class="action-title">Book Appointment</div>
                                <div class="action-desc">Help customers book new appointments and assign doctors</div>
                            </div>
                        </a>
                    </div>

                    <!-- Appointment Management -->
                    <div class="col-md-3 col-sm-6">
                        <a href="<%= request.getContextPath()%>/AppointmentServlet?action=manage" style="text-decoration: none;">
                            <div class="action-card wow fadeInUp" data-wow-delay="0.4s">
                                <div class="action-icon counter-staff">
                                    <i class="fa fa-calendar-check-o"></i>
                                </div>
                                <div class="action-title">Manage Appointments</div>
                                <div class="action-desc">Update status, reschedule, cancel and assign doctors</div>
                            </div>
                        </a>
                    </div>

                    <!-- Payment Collection -->
                    <div class="col-md-3 col-sm-6">
                        <a href="<%= request.getContextPath()%>/PaymentServlet?action=viewPayments" style="text-decoration: none;">
                            <div class="action-card wow fadeInUp" data-wow-delay="0.5s">
                                <div class="action-icon counter-staff">
                                    <i class="fa fa-credit-card"></i>
                                </div>
                                <div class="action-title">Collect Payments</div>
                                <div class="action-desc">Process payments and update payment status</div>
                            </div>
                        </a>
                    </div>
                </div>

                <!-- Second Row of Actions -->
                <div class="row" style="margin-top: 20px;">
                    <!-- Generate Receipts -->
                    <div class="col-md-3 col-sm-6">
                        <a href="<%= request.getContextPath()%>/counter_staff/generate_receipts.jsp" style="text-decoration: none;">
                            <div class="action-card wow fadeInUp" data-wow-delay="0.6s">
                                <div class="action-icon counter-staff">
                                    <i class="fa fa-file-pdf-o"></i>
                                </div>
                                <div class="action-title">Generate Receipts</div>
                                <div class="action-desc">Create and print receipts for completed payments</div>
                            </div>
                        </a>
                    </div>

                    <!-- View Treatments -->
                    <div class="col-md-3 col-sm-6">
                        <a href="<%= request.getContextPath()%>/TreatmentServlet?action=viewAll&role=staff" style="text-decoration: none;">
                            <div class="action-card wow fadeInUp" data-wow-delay="0.7s">
                                <div class="action-icon counter-staff">
                                    <i class="fa fa-stethoscope"></i>
                                </div>
                                <div class="action-title">View Treatments</div>
                                <div class="action-desc">Browse available treatments and their details</div>
                            </div>
                        </a>
                    </div>

                    <!-- My Ratings -->
                    <div class="col-md-3 col-sm-6">
                        <a href="<%= request.getContextPath()%>/CounterStaffServletJam?action=viewRatings" style="text-decoration: none;">
                            <div class="action-card wow fadeInUp" data-wow-delay="0.8s">
                                <div class="action-icon counter-staff">
                                    <i class="fa fa-star"></i>
                                </div>
                                <div class="action-title">My Ratings</div>
                                <div class="action-desc">View customer feedback and ratings received</div>
                            </div>
                        </a>
                    </div>

                    <!-- My Profile -->
                    <div class="col-md-3 col-sm-6">
                        <a href="<%= request.getContextPath()%>/profile.jsp" style="text-decoration: none;">
                            <div class="action-card wow fadeInUp" data-wow-delay="0.9s">
                                <div class="action-icon counter-staff">
                                    <i class="fa fa-user"></i>
                                </div>
                                <div class="action-title">My Profile</div>
                                <div class="action-desc">Update personal information and settings</div>
                            </div>
                        </a>
                    </div>
                </div>
            </div>
        </section>

        <!-- RECENT ACTIVITIES -->
        <section class="recent-section">
            <div class="container">
                <div class="row">
                    <!-- Priority Tasks -->
                    <div class="col-md-6">
                        <div class="section-header">
                            <h3><i class="fa fa-exclamation-triangle" style="color: #dc3545;"></i> Priority Tasks</h3>
                        </div>

                        <!-- Overdue Appointments -->
                        <% if (overdueAppointments > 0) {%>
                        <div class="priority-card wow fadeInRight animated" data-wow-delay="0.2s" style="margin-bottom: 15px; padding: 15px; border-radius: 8px; visibility: visible; animation-duration: 0.2s; animation-name: fadeInLeft">
                            <div class="row">
                                <div class="col-sm-8">
                                    <h5 style="margin: 0; color: #dc3545;">
                                        <i class="fa fa-clock-o"></i> Overdue Appointments
                                    </h5>
                                    <p style="margin: 5px 0; color: #666;">
                                        <%= overdueAppointments%> appointments need attention
                                    </p>
                                </div>
                                <div class="col-sm-4 text-right">
                                    <a href="<%= request.getContextPath()%>/AppointmentServlet?action=manage&search=&status=overdue&doctor=all&treatment=all&staff=all&date="
                                       class="btn btn-sm btn-danger">
                                        <i class="fa fa-eye"></i> View
                                    </a>
                                </div>
                            </div>
                        </div>
                        <% } %>

                        <!-- Pending Appointments -->
                        <% if (pendingAppointmentCount > 0) {%>
                        <div class="priority-card wow fadeInRight animated" data-wow-delay="0.6s" style="margin-bottom: 15px; padding: 15px; border-radius: 8px; visibility: visible; animation-duration: 0.6s; animation-name: fadeInLeft">
                            <div class="row">
                                <div class="col-sm-8">
                                    <h5 style="margin: 0; color: #ffc107;">
                                        <i class="fa fa-hourglass-half"></i> Pending Appointments
                                    </h5>
                                    <p style="margin: 5px 0; color: #666;">
                                        <%= pendingAppointmentCount%> appointments need doctor assignment
                                    </p>
                                </div>
                                <div class="col-sm-4 text-right">
                                    <a href="<%= request.getContextPath()%>/AppointmentServlet?action=manage&search=&status=pending&doctor=all&treatment=all&staff=all&date="
                                       class="btn btn-sm btn-warning">
                                        <i class="fa fa-user-md"></i> Assign
                                    </a>
                                </div>
                            </div>
                        </div>
                        <% } %>

                        <!-- Pending Payments -->
                        <% if (pendingPaymentCount > 0) {%>
                        <div class="priority-card wow fadeInRight animated" data-wow-delay="0.4s" style="margin-bottom: 15px; padding: 15px; border-radius: 8px; visibility: visible; animation-duration: 0.4s; animation-name: fadeInLeft">
                            <div class="row">
                                <div class="col-sm-8">
                                    <h5 style="margin: 0; color: #dc3545;">
                                        <i class="fa fa-credit-card"></i> Pending Payments
                                    </h5>
                                    <p style="margin: 5px 0; color: #666;">
                                        <%= pendingPaymentCount%> payments awaiting collection
                                    </p>
                                </div>
                                <div class="col-sm-4 text-right">
                                    <a href="<%= request.getContextPath()%>/PaymentServlet?action=viewPayments" 
                                       class="btn btn-sm btn-warning">
                                        <i class="fa fa-money"></i> Collect
                                    </a>
                                </div>
                            </div>
                        </div>
                        <% } %>

                        <!-- If no priority tasks -->
                        <% if (overdueAppointments == 0 && pendingPaymentCount == 0 && pendingAppointmentCount == 0) { %>
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
                            if (recentAppointments != null && !recentAppointments.isEmpty()) {
                                int maxAppointments = Math.min(5, recentAppointments.size());
                                for (int i = 0; i < maxAppointments; i++) {
                                    Appointment apt = recentAppointments.get(i);
                                    if (apt != null) {
                                        String statusClass = "status-pending";
                                        String statusText = "Pending";
                                        String actionText = "";

                                        if (apt.getStatus() != null) {
                                            String status = apt.getStatus().toLowerCase();
                                            if ("approved".equals(status)) {
                                                statusClass = "status-confirmed";
                                                statusText = "Approved";
                                                actionText = "Doctor assigned";
                                            } else if ("completed".equals(status)) {
                                                statusClass = "status-completed";
                                                statusText = "Completed";
                                                actionText = "Treatment finished";
                                            } else if ("overdue".equals(status)) {
                                                statusClass = "status-overdue";
                                                statusText = "Overdue";
                                                actionText = "Needs attention";
                                            } else if ("cancelled".equals(status)) {
                                                statusClass = "status-cancelled";
                                                statusText = "Cancelled";
                                                actionText = "By customer";
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
                            <a href="<%= request.getContextPath()%>/counter_staff/manage_appointments.jsp" class="btn btn-success">
                                <i class="fa fa-calendar"></i> View All Appointments
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
                                    <% if (loggedInStaff.getRating() != null && loggedInStaff.getRating() > 0) {%>
                                    <%= String.format("%.1f", loggedInStaff.getRating())%>/10
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
                                    <%= (todayAppointments != null ? todayAppointments.size() : 0)%>
                                </p>
                                <small style="color: #666;">Appointments today</small>
                            </div>
                        </div>
                    </div>

                    <!-- Customer Feedback -->
                    <div class="col-md-3 col-sm-6">
                        <div class="staff-card wow fadeInUp" data-wow-delay="0.4s">
                            <div class="text-center">
                                <h4 style="margin: 0; color: #333;">
                                    <i class="fa fa-comments"></i> Feedback
                                </h4>
                                <p style="margin: 10px 0; font-size: 1.5em; color: #6c757d; font-weight: bold;">
                                    <%= (recentFeedbacks != null ? recentFeedbacks.size() : 0)%>
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
                                    <%= completedAppointments%>
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
            // Counter staff specific JavaScript
            $(document).ready(function () {
                // Initialize dashboard
                console.log('Counter Staff Dashboard loaded successfully');

                // Add click tracking for dashboard actions
                $('.action-card').click(function () {
                    const actionTitle = $(this).find('.action-title').text();
                    console.log('Counter Staff action clicked:', actionTitle);
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
