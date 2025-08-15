<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="model.Doctor" %>
<%@ page import="model.CounterStaff" %>
<%@ page import="model.Manager" %>
<%@ page import="model.Appointment" %>
<%@ page import="java.text.DecimalFormat" %>

<%
    // Check if manager is logged in
    Manager loggedInManager = (Manager) session.getAttribute("manager");

    if (loggedInManager == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    } else {
        System.out.println("Manager " + loggedInManager.getName() + " logged in successfully!");
    }

    // Retrieve dashboard data from request attributes
    List<Doctor> doctorList = (List<Doctor>) request.getAttribute("doctorList");
    List<CounterStaff> staffList = (List<CounterStaff>) request.getAttribute("staffList");
    List<Manager> managerList = (List<Manager>) request.getAttribute("managerList");
    List<Appointment> recentAppointments = (List<Appointment>) request.getAttribute("recentAppointments");

    // Dashboard statistics
    Integer totalDoctors = (Integer) request.getAttribute("totalDoctors");
    Integer totalStaff = (Integer) request.getAttribute("totalStaff");
    Integer totalManagers = (Integer) request.getAttribute("totalManagers");
    Integer totalAppointments = (Integer) request.getAttribute("totalAppointments");
    Integer pendingAppointments = (Integer) request.getAttribute("pendingAppointments");
    Double totalRevenue = (Double) request.getAttribute("totalRevenue");

    // Default values if null
    if (totalDoctors == null) {
        totalDoctors = 0;
    }
    if (totalStaff == null) {
        totalStaff = 0;
    }
    if (totalManagers == null) {
        totalManagers = 0;
    }
    if (totalAppointments == null) {
        totalAppointments = 0;
    }
    if (pendingAppointments == null) {
        pendingAppointments = 0;
    }
    if (totalRevenue == null) {
        totalRevenue = 0.0;
    }

    DecimalFormat currencyFormat = new DecimalFormat("#,##0.00");
%>

<!DOCTYPE html>
<html lang="en">
    <head>
        <title>Manager Dashboard - APU Medical Center</title>
        <%@ include file="/includes/head.jsp" %>
        <link rel="stylesheet" href="<%= request.getContextPath()%>/css/manager-homepage.css">
    </head>

    <body id="top" data-spy="scroll" data-target=".navbar-collapse" data-offset="50">
        <%@ include file="/includes/header.jsp" %>
        <%@ include file="/includes/navbar.jsp" %>

        <!-- DASHBOARD STATISTICS -->
        <section id="dashboard-stats" class="dashboard-stats">
            <div class="container">
                <div class="row">
                    <div class="col-md-12">
                        <div class="section-title wow fadeInUp" data-wow-delay="0.1s">
                            <h2 style="color: white;">System Overview</h2>
                        </div>
                    </div>
                </div>
                <div class="row">
                    <div class="col-md-2 col-sm-6">
                        <div class="stat-card wow fadeInUp" data-wow-delay="0.2s">
                            <span class="stat-number"><%= totalDoctors%></span>
                            <span class="stat-label">Doctors</span>
                        </div>
                    </div>
                    <div class="col-md-2 col-sm-6">
                        <div class="stat-card wow fadeInUp" data-wow-delay="0.3s">
                            <span class="stat-number"><%= totalStaff%></span>
                            <span class="stat-label">Counter Staff</span>
                        </div>
                    </div>
                    <div class="col-md-2 col-sm-6">
                        <div class="stat-card wow fadeInUp" data-wow-delay="0.4s">
                            <span class="stat-number"><%= totalManagers%></span>
                            <span class="stat-label">Managers</span>
                        </div>
                    </div>
                    <div class="col-md-2 col-sm-6">
                        <div class="stat-card wow fadeInUp" data-wow-delay="0.5s">
                            <span class="stat-number"><%= totalAppointments%></span>
                            <span class="stat-label">Total Appointments</span>
                        </div>
                    </div>
                    <div class="col-md-2 col-sm-6">
                        <div class="stat-card wow fadeInUp" data-wow-delay="0.6s">
                            <span class="stat-number"><%= pendingAppointments%></span>
                            <span class="stat-label">Pending </span>
                        </div>
                    </div>
                      <div class="col-md-2 col-sm-6">
                        <div class="stat-card wow fadeInUp" data-wow-delay="0.7s">
                            <span class="stat-number"><%= currencyFormat.format(totalRevenue)%></span>
                            <span class="stat-label">Revenue(RM)</span>
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
                    <!-- Staff Management -->
                    <div class="col-md-4 col-sm-6">
                        <a href="<%= request.getContextPath()%>/ManagerServlet?action=viewAll" style="text-decoration: none;">
                            <div class="action-card wow fadeInUp" data-wow-delay="0.2s">
                                <div class="action-icon">
                                    <i class="fa fa-users"></i> 
                                </div>
                                <div class="action-title">Manage Staff</div>
                                <div class="action-desc">View, search or delete doctors, counter staff, and managers</div>
                            </div>
                        </a>
                    </div>

                    <!-- Appointment Management -->
                    <div class="col-md-4 col-sm-6">
                        <a href="<%= request.getContextPath()%>/ManagerServlet?action=viewAppointments" style="text-decoration: none;">
                            <div class="action-card wow fadeInUp" data-wow-delay="0.3s">
                                <div class="action-icon">
                                    <i class="fa fa-calendar"></i>
                                </div>
                                <div class="action-title">View Appointments</div>
                                <div class="action-desc">Monitor all appointments and customer/doctor comments</div>
                            </div>
                        </a>
                    </div>

                    <!-- Staff Ratings -->
                    <div class="col-md-4 col-sm-6">
                        <a href="<%= request.getContextPath()%>/StaffRatingServlet" style="text-decoration: none;">
                            <div class="action-card wow fadeInUp" data-wow-delay="0.4s">
                                <div class="action-icon">
                                    <i class="fa fa-star"></i>
                                </div>
                                <div class="action-title">Staff Ratings</div>
                                <div class="action-desc">View and analyze doctor and counter staff ratings</div>
                            </div>
                        </a>
                    </div>
                </div>

                <!-- Second Row of Actions -->
                <div class="row" style="margin-top: 20px;">
                    <!-- Reports & Analytics -->
                    <div class="col-md-4 col-sm-6">
                        <a href="<%= request.getContextPath()%>/manager/reports.jsp" style="text-decoration: none;">
                            <div class="action-card wow fadeInUp" data-wow-delay="0.5s">
                                <div class="action-icon">
                                    <i class="fa fa-bar-chart"></i>
                                </div>
                                <div class="action-title">Reports & Analytics</div>
                                <div class="action-desc">Demographics, revenue, and staff performance reports</div>
                            </div>
                        </a>
                    </div>

                    <!-- Register New Staff -->
                    <div class="col-md-4 col-sm-6">
                        <a href="<%= request.getContextPath()%>/manager/register_staff.jsp" style="text-decoration: none;">
                            <div class="action-card wow fadeInUp" data-wow-delay="0.6s">
                                <div class="action-icon">
                                    <i class="fa fa-user-plus"></i>
                                </div>
                                <div class="action-title">Register Staff</div>
                                <div class="action-desc">Add new doctors, counter staff, or managers</div>
                            </div>
                        </a>
                    </div>

                    <!-- Profile Management -->
                    <div class="col-md-4 col-sm-6">
                        <a href="<%= request.getContextPath()%>/profile.jsp" style="text-decoration: none;">
                            <div class="action-card wow fadeInUp" data-wow-delay="0.7s">
                                <div class="action-icon">
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
                    <!-- Top Performing Staff -->
                    <div class="col-md-6">
                        <div class="section-header">
                            <h3><i class="fa fa-trophy"></i> Top Performing Staff</h3>
                        </div>

                        <%
                            if (doctorList != null && !doctorList.isEmpty()) {
                                // Show top 3 doctors by rating
                                int maxDoctors = Math.min(3, doctorList.size());
                        %>
                        <h4 style="color: #667eea; margin-bottom: 15px;">
                            <i class="fa fa-user-md"></i> Top Doctors
                        </h4>
                        <%
                            for (int i = 0; i < maxDoctors; i++) {
                                Doctor doc = doctorList.get(i);
                                if (doc != null) {
                        %>
                        <div class="staff-card wow fadeInLeft" data-wow-delay="<%= 0.2 + (i * 0.1)%>s">
                            <div class="row">
                                <div class="col-sm-8">
                                    <h5 style="margin: 0; color: #333;">
                                        <%= doc.getName() != null ? doc.getName() : "N/A"%>
                                    </h5>
                                    <p style="margin: 5px 0; color: #666;">
                                        <%= doc.getSpecialization() != null ? doc.getSpecialization() : "General Practice"%>
                                    </p>
                                </div>
                                <div class="col-sm-4 text-right">
                                    <% if (doc.getRating() != null && doc.getRating() > 0) {%>
                                    <span class="rating-stars">
                                        <i class="fa fa-star"></i> <%= String.format("%.1f", doc.getRating())%>/10
                                    </span>
                                    <% } else { %>
                                    <span style="color: #999;">No ratings</span>
                                    <% } %>
                                </div>
                            </div>
                        </div>
                        <%
                                    }
                                }
                            }
                        %>

                        <%
                            if (staffList != null && !staffList.isEmpty()) {
                                // Show top 2 staff by rating
                                int maxStaff = Math.min(2, staffList.size());
                        %>
                        <h4 style="color: #667eea; margin: 25px 0 15px 0;">
                            <i class="fa fa-id-badge"></i> Top Counter Staff
                        </h4>
                        <%
                            for (int i = 0; i < maxStaff; i++) {
                                CounterStaff staff = staffList.get(i);
                                if (staff != null) {
                        %>
                        <div class="staff-card wow fadeInLeft" data-wow-delay="<%= 0.5 + (i * 0.1)%>s">
                            <div class="row">
                                <div class="col-sm-8">
                                    <h5 style="margin: 0; color: #333;">
                                        <%= staff.getName() != null ? staff.getName() : "N/A"%>
                                    </h5>
                                </div>
                                <div class="col-sm-4 text-right">
                                    <% if (staff.getRating() != null && staff.getRating() > 0) {%>
                                    <span class="rating-stars">
                                        <i class="fa fa-star"></i> <%= String.format("%.1f", staff.getRating())%>/10
                                    </span>
                                    <% } else { %>
                                    <span style="color: #999;">No ratings</span>
                                    <% } %>
                                </div>
                            </div>
                        </div>
                        <%
                                    }
                                }
                            }
                        %>
                    </div>

                    <!-- Recent Appointments -->
                    <div class="col-md-6">
                        <div class="section-header">
                            <h3><i class="fa fa-calendar-check-o"></i> Recent Appointments</h3>
                        </div>

                        <%
                            if (recentAppointments != null && !recentAppointments.isEmpty()) {
                                int maxAppointments = Math.min(5, recentAppointments.size());
                                for (int i = 0; i < maxAppointments; i++) {
                                    Appointment apt = recentAppointments.get(i);
                                    if (apt != null) {
                                        String statusClass = "status-pending";
                                        String statusText = "Pending";

                                        if (apt.getStatus() != null) {
                                            String status = apt.getStatus().toLowerCase();
                                            if ("confirmed".equals(status)) {
                                                statusClass = "status-confirmed";
                                                statusText = "Confirmed";
                                            } else if ("completed".equals(status)) {
                                                statusClass = "status-completed";
                                                statusText = "Completed";
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
                                        Dr. <%= apt.getDoctor() != null ? apt.getDoctor().getName() : "N/A"%>
                                    </p>
                                    <small style="color: #999;">
                                        <%= apt.getAppointmentDate() != null ? apt.getAppointmentDate().toString() : "N/A"%>
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
                            No recent appointments to display.
                        </div>
                        <% }%>

                        <div class="text-center" style="margin-top: 20px;">
                            <a href="<%= request.getContextPath()%>/ManagerServlet?action=viewAppointments" class="btn btn-primary">
                                View All Appointments
                            </a>
                        </div>
                    </div>
                </div>
            </div>
        </section>

        <%@ include file="/includes/footer.jsp" %>
        <%@ include file="/includes/scripts.jsp" %>

        <script>
            // Add any manager-specific JavaScript here
            $(document).ready(function () {
                // Initialize any charts or interactive elements
                console.log('Manager Dashboard loaded successfully');

                // Add click tracking for dashboard actions
                $('.action-card').click(function () {
                    const actionTitle = $(this).find('.action-title').text();
                    console.log('Manager action clicked:', actionTitle);
                });
            });
        </script>
    </body>
</html>