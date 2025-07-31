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
    Customer viewCustomer = (Customer) request.getAttribute("viewCustomer");
    
    if (viewCustomer == null) {
        response.sendRedirect(request.getContextPath() + "/CustomerServlet?action=viewAll&error=customer_not_found");
        return;
    }

    SimpleDateFormat dateFormat = new SimpleDateFormat("dd MMM yyyy");
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
            
            .actions {
                text-align: center;
                padding: 20px 0;
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
            
            .btn-edit {
                background: #FF9800;
                color: white;
            }
            
            .btn-edit:hover {
                background: #F57C00;
                color: white;
                text-decoration: none;
            }
            
            .btn-back {
                background: #6c757d;
                color: white;
            }
            
            .btn-back:hover {
                background: #545b62;
                color: white;
                text-decoration: none;
            }
            
            .status-badge {
                display: inline-block;
                padding: 4px 12px;
                border-radius: 20px;
                font-size: 12px;
                font-weight: 600;
                background: #4CAF50;
                color: white;
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
                                    <a href="<%= request.getContextPath()%>/CounterStaffServlet?action=dashboard" style="color: rgba(255,255,255,0.8);">Dashboard</a>
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
                            <% if (viewCustomer.getProfilePic() != null && !viewCustomer.getProfilePic().isEmpty()) { %>
                                <img src="<%= request.getContextPath()%>/uploads/<%= viewCustomer.getProfilePic()%>" alt="Profile Picture">
                            <% } else { %>
                                <i class="fa fa-user"></i>
                            <% } %>
                        </div>
                        <h2><%= viewCustomer.getName()%></h2>
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
                                <div class="info-label">Phone Number</div>
                                <div class="info-value">
                                    <i class="fa fa-phone"></i> 
                                    <%= viewCustomer.getPhone() != null ? viewCustomer.getPhone() : "Not provided"%>
                                </div>
                            </div>
                            
                            <div class="info-item">
                                <div class="info-label">Gender</div>
                                <div class="info-value">
                                    <i class="fa fa-venus-mars"></i>
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
                        </div>
                        
                        <div class="actions">
                            <a href="<%= request.getContextPath()%>/CustomerServlet?action=edit&id=<%= viewCustomer.getId()%>" class="btn-action btn-edit">
                                <i class="fa fa-edit"></i> Edit Customer
                            </a>
                            <a href="<%= request.getContextPath()%>/CustomerServlet?action=viewAll" class="btn-action btn-back">
                                <i class="fa fa-arrow-left"></i> Back to List
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
