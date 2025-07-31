<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="model.Manager" %>
<%@ page import="java.text.SimpleDateFormat" %>

<%
    // Check if manager is logged in
    Manager loggedInManager = (Manager) session.getAttribute("manager");
    if (loggedInManager == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    // Get the manager data (can come from either attribute name)
    Manager viewManager = (Manager) request.getAttribute("manager");
    if (viewManager == null) {
        viewManager = (Manager) request.getAttribute("viewManager");
    }

    if (viewManager == null) {
        response.sendRedirect(request.getContextPath() + "/ManagerServlet?action=viewAll&error=manager_not_found");
        return;
    }

    SimpleDateFormat dateFormat = new SimpleDateFormat("dd MMM yyyy");

    String managerPic = viewManager.getProfilePic();
    String profilePic = (managerPic != null && !managerPic.isEmpty())
            ? (request.getContextPath() + "/ImageServlet?folder=profile_pictures&file=" + managerPic)
            : (request.getContextPath() + "/images/placeholder/user.png");
%>

<!DOCTYPE html>
<html lang="en">
    <head>
        <title>View Manager - <%= viewManager.getName()%> - APU Medical Center</title>
        <%@ include file="/includes/head.jsp" %>
        <link rel="stylesheet" href="<%= request.getContextPath()%>/css/manager-homepage.css">
        <style>
            .page-header {
                background: linear-gradient(135deg, #9C27B0 0%, #7B1FA2 100%);
                color: white;
                padding: 60px 0 40px 0;
            }

            .manager-details {
                background: white;
                border-radius: 12px;
                box-shadow: 0 4px 20px rgba(0,0,0,0.1);
                overflow: hidden;
                margin-bottom: 30px;
            }

            .manager-header {
                background: linear-gradient(135deg, #9C27B0, #7B1FA2);
                color: white;
                padding: 30px;
                text-align: center;
            }

            .manager-avatar {
                width: 120px;
                height: 120px;
                border-radius: 50%;
                margin: 0 auto 20px;
                border: 4px solid rgba(255,255,255,0.3);
                overflow: hidden;
                background: rgba(255,255,255,0.1);
            }

            .manager-avatar img {
                width: 100%;
                height: 100%;
                object-fit: cover;
            }

            .manager-avatar i {
                font-size: 60px;
                line-height: 112px;
                color: rgba(255,255,255,0.8);
            }

            .manager-info {
                padding: 30px;
            }

            .info-grid {
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
                gap: 20px;
                margin-bottom: 30px;
            }

            .info-item {
                padding: 15px;
                background: #f8f9fa;
                border-radius: 8px;
                border-left: 4px solid #9C27B0;
            }

            .info-label {
                font-weight: 600;
                color: #666;
                font-size: 14px;
                margin-bottom: 5px;
            }

            .info-value {
                font-size: 16px;
                color: #333;
                font-weight: 500;
            }

            .role-badge {
                background: #9C27B0;
                color: white;
                padding: 8px 16px;
                border-radius: 20px;
                font-size: 14px;
                font-weight: 500;
            }

            .current-user-badge {
                background: #4CAF50;
                color: white;
                padding: 8px 16px;
                border-radius: 20px;
                font-size: 14px;
                font-weight: 500;
                margin-left: 10px;
            }

            .action-buttons {
                text-align: center;
                padding: 20px;
                border-top: 1px solid #eee;
            }

            .btn-action {
                margin: 0 10px;
                padding: 12px 24px;
                border-radius: 25px;
                font-weight: 600;
                text-decoration: none;
                display: inline-block;
                transition: all 0.3s ease;
            }

            .btn-edit {
                background: #2196F3;
                color: white;
                border: 2px solid #2196F3;
            }

            .btn-edit:hover {
                background: #1976D2;
                border-color: #1976D2;
                color: white;
            }

            .btn-delete {
                background: transparent;
                color: #f44336;
                border: 2px solid #f44336;
            }

            .btn-delete:hover {
                background: #f44336;
                color: white;
            }

            .btn-back {
                background: #6c757d;
                color: white;
                border: 2px solid #6c757d;
            }

            .btn-back:hover {
                background: #5a6268;
                border-color: #5a6268;
                color: white;
            }

            .btn-disabled {
                background: #e0e0e0;
                color: #9e9e9e;
                border: 2px solid #e0e0e0;
                cursor: not-allowed;
            }
        </style>
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
                            <i class="fa fa-cog" style="color:white"></i>
                            <span style="color:white">Manager Profile</span>
                        </h1>
                        <nav aria-label="breadcrumb" class="wow fadeInUp" data-wow-delay="0.3s">
                            <ol class="breadcrumb" style="background: transparent; margin: 0;">
                                <li class="breadcrumb-item">
                                    <a href="<%= request.getContextPath()%>/ManagerServlet?action=viewAll" style="color: rgba(255,255,255,0.8);">Staff Management</a>
                                </li>
                                <li class="breadcrumb-item active" style="color: white;">Manager Profile</li>
                            </ol>
                        </nav>
                    </div>
                </div>
            </div>
        </section>

        <!-- MAIN CONTENT -->
        <section style="padding: 40px 0; background: #f5f5f5;">
            <div class="container">
                <div class="manager-details wow fadeInUp">
                    <!-- Manager Header -->
                    <div class="manager-header">
                        <div class="manager-avatar">
                            <img src="<%= profilePic%>" class="profile-pic" alt="<%= profilePic%> Profile Picture">
                        </div>
                        <h2 style="color: white"><%= viewManager.getName()%></h2>
                        <div>
                            <div class="role-badge">
                                System Manager
                            </div>
                            <br>
                            <% if (viewManager.getId() == loggedInManager.getId()) { %>
                            <div class="current-user-badge">
                                Current User
                            </div>
                            <% }%>
                        </div>
                    </div>

                    <!-- Manager Information -->
                    <div class="manager-info">
                        <div class="info-grid">
                            <div class="info-item">
                                <div class="info-label">Manager ID</div>
                                <div class="info-value">#<%= viewManager.getId()%></div>
                            </div>

                            <div class="info-item">
                                <div class="info-label">Full Name</div>
                                <div class="info-value"><%= viewManager.getName()%></div>
                            </div>

                            <div class="info-item">
                                <div class="info-label">Email Address</div>
                                <div class="info-value">
                                    <i class="fa fa-envelope"></i> <%= viewManager.getEmail()%>
                                </div>
                            </div>

                            <div class="info-item">
                                <div class="info-label">NRIC</div>
                                <div class="info-value">
                                    <i class="fa fa-id-card"></i>
                                    <%= viewManager.getIc() != null && !viewManager.getIc().isEmpty() ? viewManager.geIc() : "Not provided"%>
                                </div>
                            </div>

                            <div class="info-item">
                                <div class="info-label">Phone Number</div>
                                <div class="info-value">
                                    <i class="fa fa-phone"></i> 
                                    <%= viewManager.getPhone() != null && !viewManager.getPhone().isEmpty() ? viewManager.getPhone() : "Not provided"%>
                                </div>
                            </div>

                            <div class="info-item">
                                <div class="info-label">Gender</div>
                                <div class="info-value">
                                    <i class="fa <%= viewManager.getGender() != null && viewManager.getGender().equals("M") ? "fa-mars" : "fa-venus"%>"></i>
                                    <%= viewManager.getGender() != null ? (viewManager.getGender().equals("M") ? "Male" : "Female") : "Not specified"%>
                                </div>
                            </div>

                            <div class="info-item">
                                <div class="info-label">Date of Birth</div>
                                <div class="info-value">
                                    <i class="fa fa-calendar"></i>
                                    <%= viewManager.getDob() != null ? dateFormat.format(viewManager.getDob()) : "Not provided"%>
                                </div>
                            </div>

                            <div class="info-item">
                                <div class="info-label">Address</div>
                                <div class="info-value">
                                    <i class="fa fa-map-marker"></i>
                                    <%= viewManager.getAddress() != null && !viewManager.getAddress().isEmpty() ? viewManager.getAddress() : "Not provided"%>
                                </div>
                            </div>

                            <div class="info-item">
                                <div class="info-label">Authority Level</div>
                                <div class="info-value">
                                    <i class="fa fa-shield"></i>
                                    System Administrator
                                </div>
                            </div>

                            <div class="info-item">
                                <div class="info-label">Access Permissions</div>
                                <div class="info-value">
                                    <i class="fa fa-key"></i>
                                    Full System Access
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Action Buttons -->
                    <div class="action-buttons">
                        <a href="<%= request.getContextPath()%>/ManagerServlet?action=viewAll" class="btn-action btn-back">
                            <i class="fa fa-arrow-left"></i> Back to Staff List
                        </a>
                    </div>
                </div>
            </div>
        </section>

        <%@ include file="/includes/footer.jsp" %>
        <%@ include file="/includes/scripts.jsp" %>
    </body>
</html>
