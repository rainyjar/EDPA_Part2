<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="model.Manager" %>

<%
    // Check if manager is logged in
    Manager loggedInManager = (Manager) session.getAttribute("manager");

    if (loggedInManager == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
%>

<!DOCTYPE html>
<html lang="en">
    <head>
        <title>Manage Staff - APU Medical Center</title>
        <%@ include file="/includes/head.jsp" %>
        <link rel="stylesheet" href="<%= request.getContextPath()%>/css/manager-homepage.css">
        <link rel="stylesheet" href="<%= request.getContextPath()%>/css/manage-staff.css">
    </head>

    <body id="top">
        <%@ include file="/includes/header.jsp" %>
        <%@ include file="/includes/navbar.jsp" %>

        <!-- PAGE HEADER -->
        <section class="page-header">
            <div class="container">
                <div class="row">
                    <div class="col-md-12">
                        <h1 class="wow fadeInUp">
                            <i class="fa fa-user-plus" style="color:white"></i>
                            <span style="color:white">Register Staff</span>
                        </h1>
                        <p class="lead wow fadeInUp" data-wow-delay="0.2s" style="color: whitesmoke">
                            Add new doctors, counter staff, or managers
                        </p>
                        <nav aria-label="breadcrumb" class="wow fadeInUp" data-wow-delay="0.3s">
                            <ol class="breadcrumb" style="background: transparent; margin: 0;">
                                <li class="breadcrumb-item">
                                    <a href="<%= request.getContextPath()%>/ManagerHomepageServlet" style="color: rgba(255,255,255,0.8);">Dashboard</a>
                                </li>
                                <li class="breadcrumb-item active" style="color: white;">Register Staff</li>
                            </ol>
                        </nav>
                    </div>
                </div>
            </div>
        </section>

        <!-- MAIN CONTENT -->
        <section style="padding: 40px 0; background: #f5f5f5;">
            <div class="container">
                <!-- STAFF MANAGEMENT SECTION -->
                <div class="row">
                    <div class="staff-management-section wow fadeInUp" data-wow-delay="0.2s">
                        <h2 class="mb-4">Select your choice:</h2>
                        <div class="row">
                            <div class="col-md-4">
                                <div class="card shadow-sm text-center p-3">
                                    <h4><i class="fa fa-user-md" style="color: #667eea"></i> Doctor</h4>
                                    <p>Register a new doctor profile.</p>
                                    <a href="${pageContext.request.contextPath}/manager/register_doctor.jsp" class="add-doc-btn">Register Doctor</a>
                                </div>
                            </div>

                            <div class="col-md-4">
                                <div class="card shadow-sm text-center p-3">
                                    <h4> <i class="fa fa-id-badge" style="color: #F57C00"></i> Counter Staff</h4>
                                    <p>Register new front-desk counter staff.</p>
                                    <a href="${pageContext.request.contextPath}/manager/register_cs.jsp" class="add-cs-btn">Register Counter Staff</a>
                                </div>
                            </div>

                            <div class="col-md-4">
                                <div class="card shadow-sm text-center p-3">
                                    <h4><i class="fa fa-cog" style="color: #9C27B0"></i> Manager</h4>
                                    <p>Add another manager to the system.</p>
                                    <a href="${pageContext.request.contextPath}/manager/register_manager.jsp" class="add-man-btn">Register Manager</a> 
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </section>

        <%@ include file="/includes/footer.jsp" %>
        <%@ include file="/includes/scripts.jsp" %>

        <script>
            // Auto-dismiss alerts
            $(document).ready(function () {
                setTimeout(function () {
                    $('.alert').fadeOut();
                }, 5000);

                // Initialize tooltips
                $('[data-toggle="tooltip"]').tooltip();
            });

        </script>
    </body>
</html>