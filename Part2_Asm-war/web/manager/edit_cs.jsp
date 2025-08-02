<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@page import="model.Manager"%>

<%
    Manager loggedInManager = (Manager) session.getAttribute("manager");
    if (loggedInManager == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    Manager manager = (Manager) request.getAttribute("manager");
%>

<!DOCTYPE html>
<html lang="en">
    <head>
        <title>Edit Counter Staff - APU Medical Center</title>
        <%@ include file="/includes/head.jsp" %>
        <link rel="stylesheet" href="${pageContext.request.contextPath}/css/user-reg-edit.css" />
    </head>
    <body class="staff-theme">
        <%@ include file="/includes/header.jsp" %>
        <%@ include file="/includes/navbar.jsp" %>

        <div class="registration-container">
            <a href="${pageContext.request.contextPath}/CounterStaffServlet?action=viewAll" class="back-btn" style="margin-top: 30px; margin-bottom: 30px">
                <i class="fa fa-arrow-left"></i> Back to Staff Management
            </a>

            <div class="registration-card">
                <div class="card-header staff">
                    <h2>
                        <i class="fa fa-id-badge role-icon"></i>
                        <span>Edit Counter Staff</span>
                    </h2>
                </div>

                <div class="form-container">
                    <% if (request.getAttribute("success") != null) {%>
                    <div class="alert alert-success">
                        <i class="fa fa-check-circle"></i>
                        <%= request.getAttribute("success")%>
                    </div>
                    <% }%>

                    <% if (request.getAttribute("error") != null) {%>
                    <div class="alert alert-error">
                        <i class="fa fa-exclamation-triangle"></i>
                        <%= request.getAttribute("error")%>
                    </div>
                    <% }%>

                    <form id="staffForm" method="post" enctype="multipart/form-data"
                          action="${pageContext.request.contextPath}/CounterStaffServlet?action=update&id=${counterStaff.id}" novalidate>

                        <!-- Personal Information -->
                        <div class="form-row">
                            <div class="form-group">
                                <label for="name">Full Name <span class="required">*</span></label>
                                <input type="text" id="name" name="name" class="form-control staff"
                                       value="${counterStaff.name}" placeholder="Enter full name" required>
                                <div class="invalid-feedback"></div>
                            </div>

                            <div class="form-group">
                                <label for="email">Email Address <span class="required">*</span></label>
                                <input type="email" id="email" name="email" class="form-control staff"
                                       value="${counterStaff.email}" placeholder="counterStaff@example.com" required>
                                <div class="invalid-feedback"></div>
                            </div>
                        </div>

                        <div class="form-row">
                            <div class="form-group">
                                <label for="password">Password <span class="required">*</span></label>
                                <input type="password" id="password" name="password" class="form-control staff"
                                       value="${counterStaff.password}" placeholder="Minimum 6 characters" required>
                                <div class="invalid-feedback"></div>
                            </div>

                            <div class="form-group">
                                <label for="phone">Phone Number <span class="required">*</span></label>
                                <input type="tel" id="phone" name="phone" class="form-control staff"
                                       value="${counterStaff.phone}" placeholder="e.g., 60123456789" required>
                                <div class="invalid-feedback"></div>
                            </div>
                        </div>

                        <div class="form-row">
                            <div class="form-group">
                                <label for="nric">NRIC <span class="required">*</span></label>
                                <input type="text" id="nric" name="nric" class="form-control staff" 
                                       value="${counterStaff != null ? counterStaff.ic : ''}" required>
                                <div class="invalid-feedback" id="icError"></div>
                            </div>

                            <div class="form-group">
                                <label for="gender">Gender <span class="required">*</span></label>
                                <select id="gender" name="gender" class="form-control staff" required>
                                    <option value="" disabled ${counterStaff.gender == null ? "selected" : ""}>Select Gender</option>
                                    <option value="F" ${counterStaff.gender == 'F' ? "selected" : ""}>Female</option>
                                    <option value="M" ${counterStaff.gender == 'M' ? "selected" : ""}>Male</option>
                                </select>
                                <div class="invalid-feedback"></div>
                            </div>
                        </div>

                        <div class="form-group">
                            <label for="address">Address <span class="required">*</span></label>
                            <textarea id="address" name="address" class="form-control staff" style="resize: none;" rows="3" required>
                                ${counterStaff != null ? counterStaff.address : ''}
                            </textarea>
                            <div class="invalid-feedback"></div>
                        </div>

                        <div class="form-row">
                            <div class="form-group">
                                <label for="dob">Date of Birth <span class="required">*</span></label>
                                <input type="date" id="dob" name="dob" class="form-control staff"
                                       value="${counterStaff.dob}" required style="line-height: normal">
                                <div class="invalid-feedback"></div>
                            </div>
                        </div>

                        <!-- Profile Picture -->
                        <div class="form-group">
                            <label for="profilePic">Profile Picture <span class="required">*</span></label>
                            <div class="file-upload">
                                <div class="file-upload-wrapper">
                                    <input type="file" class="form-control" id="profilePic" name="profilePic" accept="image/*">
                                    <label for="profilePic" class="file-upload-btn" id="fileLabel">
                                        <i class="fa fa-cloud-upload"></i>
                                        <span>Choose Profile Picture</span>
                                    </label>
                                </div>
                                <div class="invalid-feedback"  id="profilePicError" style="display: block;"></div> <!-- Make sure it's visible -->
                            </div>
                        </div>

                        <button type="submit" class="submit-btn staff" id="submitBtn">
                            <span class="btn-text">
                                <i class="fa fa-save"></i>
                                Edit Counter Staff
                            </span>
                        </button>
                    </form>
                </div>
            </div>
        </div>

        <%@ include file="/includes/footer.jsp" %>
        <%@ include file="/includes/scripts.jsp" %>

        <script src="${pageContext.request.contextPath}/js/jquery.min.js"></script>
        <script src="<%= request.getContextPath()%>/js/validate-register.js"></script>
    </body>
</html>
