<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="model.Manager" %>

<%
    Manager loggedInManager = (Manager) session.getAttribute("manager");

    if (loggedInManager == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html lang="en">
    <head>
        <title>Register Manager - APU Medical Center</title>
        <%@ include file="/includes/head.jsp" %>
        <link rel="stylesheet" href="${pageContext.request.contextPath}/css/user-reg-edit.css" />
    </head>
    <body class="manager-theme">
        <%@ include file="/includes/header.jsp" %>
        <%@ include file="/includes/navbar.jsp" %>
        <div class="registration-container">
            <a href="${pageContext.request.contextPath}/manager/register_staff.jsp" class="back-btn" style="margin-top: 30px; margin-bottom: 30px">
                <i class="fa fa-arrow-left"></i> Back to Registering Staff
            </a>

            <div class="registration-card">
                <div class="card-header manager">
                    <h2>
                        <i class="fa fa-cog role-icon"></i>
                        <span>New Manager Registration</span>
                    </h2>
                </div>

                <div class="form-container">
                    <!-- Success Message -->
                    <% if (request.getAttribute("success") != null) {%>
                    <div class="alert alert-success">
                        <i class="fa fa-check-circle"></i>
                        <%= request.getAttribute("success")%>
                    </div>
                    <% }%>

                    <!-- Error Message -->
                    <% if (request.getAttribute("error") != null) {%>
                    <div class="alert alert-error">
                        <i class="fa fa-exclamation-triangle"></i>
                        <%= request.getAttribute("error")%>
                    </div>
                    <% }%>

                    <form id="managerForm" method="post" enctype="multipart/form-data" action="${pageContext.request.contextPath}/ManagerServlet?action=register" novalidate>

                        <!-- Personal Information Section -->
                        <div class="form-row">
                            <div class="form-group">
                                <label for="name">Full Name <span class="required">*</span></label>
                                <input type="text" id="name" name="name" class="form-control manager" 
                                       value="${formManager  != null ? formManager .name : ''}" 
                                       placeholder="Enter full name" required>
                                <div class="invalid-feedback"></div>
                            </div>

                            <div class="form-group">
                                <label for="email">Email Address <span class="required">*</span></label>
                                <input type="email" id="email" name="email" class="form-control manager" 
                                       value="${formManager  != null ? formManager .email : ''}" 
                                       placeholder="manager@example.com" required>
                                <div class="invalid-feedback"></div>
                            </div>
                        </div>

                        <div class="form-row">
                            <div class="form-group">
                                <label for="password">Password <span class="required">*</span></label>
                                <input type="password" id="password" name="password" class="form-control manager" 
                                       value="${formManager  != null ? formManager .password : ''}" 
                                       placeholder="Minimum 6 characters" required>
                                <div class="invalid-feedback"></div>
                            </div>
                            <div class="form-group">
                                <label for="phone">Phone Number <span class="required">*</span></label>
                                <input type="tel" id="phone" name="phone" class="form-control manager" 
                                       value="${formManager  != null ? formManager .phone : ''}" 
                                       placeholder="e.g., 60123456789" required>
                                <div class="invalid-feedback"></div>
                            </div>
                        </div>

                        <div class="form-row">
                            <div class="form-group">
                                <label for="nric">NRIC <span class="required">*</span></label>
                                <input type="text" id="nric" name="nric" class="form-control manager" required>
                                <div class="invalid-feedback" id="icError"></div>
                            </div>

                            <div class="form-group">
                                <label for="gender">Gender <span class="required">*</span></label>
                                <select id="gender" name="gender" class="form-control manager" required>
                                    <option value="" disabled ${formManager  == null ? "selected" : ""}>Select Gender</option>
                                    <option value="F" ${formManager  != null && formManager .gender == 'F' ? "selected" : ""}>Female</option>
                                    <option value="M" ${formManager  != null && formManager .gender == 'M' ? "selected" : ""}>Male</option>
                                </select>
                                <div class="invalid-feedback"></div>
                            </div>
                        </div>

                        <div class="form-group">
                            <label for="address">Address <span class="required">*</span></label>
                            <textarea id="address" name="address" class="form-control manager" style="resize: none;" rows="3" required></textarea>
                            <div class="invalid-feedback"></div>
                        </div>

                        <div class="form-group">
                            <label for="dob">Date of Birth <span class="required">*</span></label>
                            <input type="date" id="dob" name="dob" class="form-control manager" 
                                   value="${formManager  != null ? formManager.dob : ''}" required style="line-height: normal">
                            <div class="invalid-feedback"></div>
                        </div>

                        <!-- Profile Picture Section -->
                        <div class="form-group">
                            <label for="profilePic">Profile Picture <span class="required">*</span></label>

                            <div class="file-upload">
                                <div class="file-upload-wrapper">
                                    <input type="file" class="form-control" id="profilePic" name="profilePic" accept="image/*" required>
                                    <label for="profilePic" class="file-upload-btn" id="fileLabel">
                                        <i class="fa fa-cloud-upload"></i>
                                        <span>Choose Profile Picture</span>
                                    </label>
                                </div>
                                <div class="invalid-feedback"  id="profilePicError" style="display: block;"></div> <!-- Make sure it's visible -->
                            </div>
                        </div>

                        <!-- Admin Notice -->
                        <div class="alert" style="background-color: #fff3cd; color: #856404; border-left: 4px solid #ffc107;">
                            <i class="fa fa-info-circle"></i>
                            <strong>Administrative Notice:</strong> This manager will have full system access and administrative privileges.
                        </div>

                        <button type="submit" class="submit-btn manager" id="submitBtn">
                            <span class="btn-text">
                                <i class="fa fa-user-plus"></i>
                                Register Manager
                            </span>
                        </button>
                    </form>
                    <a href="${pageContext.request.contextPath}/ManagerServlet?action=viewAll" class="back-btn" style="margin-top: 30px" >

                        <i class="fa fa-arrow-left"></i> Back to Staff Management

                    </a>
                </div>
            </div>
        </div>
        <%@ include file="/includes/footer.jsp" %>
        <%@ include file="/includes/scripts.jsp" %>

        <script src="${pageContext.request.contextPath}/js/jquery.min.js"></script>
        <script src="<%= request.getContextPath()%>/js/validate-register.js"></script>
    </body>
</html>
