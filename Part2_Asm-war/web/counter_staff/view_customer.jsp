<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="model.Customer" %>
<%@ page import="model.CounterStaff" %>
<%@ page import="java.text.SimpleDateFormat" %>

<%
    // Check if counter staff is logged in
    CounterStaff loggedInStaff = (CounterStaff) session.getAttribute("staff");
    if (loggedInStaff == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    // Get the customer data
    Customer viewCustomer = (Customer) request.getAttribute("customer");

    if (viewCustomer == null) {
        response.sendRedirect(request.getContextPath() + "/CustomerServlet?action=viewAll&error=customer_not_found");
        return;
    }

    SimpleDateFormat dateFormat = new SimpleDateFormat("dd MMM yyyy");

    String customerPic = viewCustomer.getProfilePic();
    String profilePic = (customerPic != null && !customerPic.isEmpty())
            ? (request.getContextPath() + "/ImageServlet?folder=profile_pictures&file=" + customerPic)
            : (request.getContextPath() + "/images/placeholder/user.png");
%>

<!DOCTYPE html>
<html lang="en">
    <head>
        <title>View Customer - <%= viewCustomer.getName()%> - APU Medical Center</title>
        <%@ include file="/includes/head.jsp" %>
        <link rel="stylesheet" href="<%= request.getContextPath()%>/css/manager-homepage.css">
        <style>
            .page-header {
                background: linear-gradient(135deg, #4CAF50 0%, #2E7D32 100%);
                color: white;
                padding: 60px 0 40px 0;
            }
            
            .role-badge {
                background: #4CAF50;
                color: white;
                padding: 8px 16px;
                border-radius: 20px;
                font-size: 14px;
                font-weight: 500;
            }

            .customer-details {
                background: white;
                border-radius: 12px;
                box-shadow: 0 4px 20px rgba(0,0,0,0.1);
                overflow: hidden;
                margin-bottom: 30px;
            }

            .customer-header {
                background: linear-gradient(135deg, #4CAF50, #2E7D32);
                color: white;
                padding: 30px;
                text-align: center;
            }

            .customer-avatar {
                width: 120px;
                height: 120px;
                border-radius: 50%;
                margin: 0 auto 20px;
                border: 4px solid rgba(255,255,255,0.3);
                overflow: hidden;
                background: rgba(255,255,255,0.1);
            }

            .customer-avatar img {
                width: 100%;
                height: 100%;
                object-fit: cover;
            }

            .customer-avatar i {
                font-size: 60px;
                line-height: 112px;
                color: rgba(255,255,255,0.8);
            }

            .customer-info {
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
                border-left: 4px solid #4CAF50;
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
                word-break: break-word;
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
                text-decoration: none;
                display: inline-block;
                font-weight: 600;
                transition: all 0.3s ease;
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
                            <i class="fa fa-user" style="color:white"></i>
                            <span style="color:white">Customer Details</span>
                        </h1>
                        <p class="lead wow fadeInUp" data-wow-delay="0.2s" style="color: whitesmoke">
                            Viewing information for <%= viewCustomer.getName()%>
                        </p>
                        <nav aria-label="breadcrumb" class="wow fadeInUp" data-wow-delay="0.3s">
                            <ol class="breadcrumb" style="background: transparent; margin: 0;">
                                <li class="breadcrumb-item">
                                    <a href="<%= request.getContextPath()%>/CounterStaffServletJam?action=dashboard" style="color: rgba(255,255,255,0.8);">Dashboard</a>
                                </li>
                                <li class="breadcrumb-item">
                                    <a href="<%= request.getContextPath()%>/CustomerServlet?action=viewAll" style="color: rgba(255,255,255,0.8);">Manage Customers</a>
                                </li>
                                <li class="breadcrumb-item active" style="color: white;">View Customer</li>
                            </ol>
                        </nav>
                    </div>
                </div>
            </div>
        </section>

        <!-- MAIN CONTENT -->
        <section style="padding: 40px 0; background: #f5f5f5;">
            <div class="container">
                <div class="customer-details wow fadeInUp">
                    <div class="customer-header">
                        <div class="customer-avatar">
                            <img src="<%= profilePic%>" class="profile-pic" alt="<%= profilePic%> Profile Picture">
                        </div>
                        <h2 style="color: white"><%= viewCustomer.getName()%></h2>
                        <div class="role-badge">
                            Customer
                        </div>
                    </div>

                    <div class="customer-info">
                        <div class="info-grid">
                            <div class="info-item">
                                <div class="info-label">Customer ID</div>
                                <div class="info-value">#<%= viewCustomer.getId()%></div>
                            </div>

                            <div class="info-item">
                                <div class="info-label">Full Name</div>
                                <div class="info-value"><%= viewCustomer.getName()%></div>
                            </div>

                            <div class="info-item">
                                <div class="info-label">Email Address</div>
                                <div class="info-value">
                                    <i class="fa fa-envelope"></i> <%= viewCustomer.getEmail()%>
                                </div>
                            </div>

                            <div class="info-item">
                                <div class="info-label">NRIC</div>
                                <div class="info-value">
                                    <i class="fa fa-id-card"></i>
                                    <%= viewCustomer.getIc() != null && !viewCustomer.getIc().isEmpty() ? viewCustomer.getIc() : "Not provided"%>
                                </div>
                            </div>    

                            <div class="info-item">
                                <div class="info-label">Phone Number</div>
                                <div class="info-value">
                                    <i class="fa fa-phone"></i> 
                                    <%= viewCustomer.getPhone() != null && !viewCustomer.getPhone().isEmpty() ? viewCustomer.getPhone() : "Not provided"%>
                                </div>
                            </div>

                            <div class="info-item">
                                <div class="info-label">Gender</div>
                                <div class="info-value">
                                    <i class="fa <%= viewCustomer.getGender() != null && viewCustomer.getGender().equals("M") ? "fa-mars" : "fa-venus"%>"></i>
                                    <%= viewCustomer.getGender() != null ? (viewCustomer.getGender().equals("M") ? "Male" : "Female") : "Not specified"%>
                                </div>
                            </div>

                            <div class="info-item">
                                <div class="info-label">Date of Birth</div>
                                <div class="info-value">
                                    <i class="fa fa-calendar"></i>
                                    <%= viewCustomer.getDob() != null ? dateFormat.format(viewCustomer.getDob()) : "Not provided"%>
                                </div>
                            </div>

                            <div class="info-item">
                                <div class="info-label">Address</div>
                                <div class="info-value">
                                    <i class="fa fa-map-marker"></i>
                                    <%= viewCustomer.getAddress() != null && !viewCustomer.getAddress().isEmpty() ? viewCustomer.getAddress() : "Not provided"%>
                                </div>
                            </div>
                        </div>

                        <div class="action-buttons">
                            <a href="<%= request.getContextPath()%>/CustomerServlet?action=viewAll" class="btn-action btn-back">
                                <i class="fa fa-arrow-left"></i> Back to Customer List
                            </a>
                        </div>
                    </div>
                </div>
            </div>
        </section>

        <%@ include file="/includes/footer.jsp" %>
        <%@ include file="/includes/scripts.jsp" %>
    </body>
</html>
