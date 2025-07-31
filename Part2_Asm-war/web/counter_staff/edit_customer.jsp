<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="model.Customer" %>
<%@ page import="model.CounterStaff" %>

<%
    // Check if counter staff is logged in
    CounterStaff loggedInStaff = (CounterStaff) session.getAttribute("staff");
    if (loggedInStaff == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    // Get the customer data for editing
    Customer customer = (Customer) request.getAttribute("customer");
    
    if (customer == null) {
        response.sendRedirect(request.getContextPath() + "/CustomerServlet?action=viewAll&error=customer_not_found");
        return;
    }
%>

<!DOCTYPE html>
<html lang="en">
    <head>
        <title>Edit Customer - <%= customer.getName()%> - APU Medical Center</title>
        <%@ include file="/includes/head.jsp" %>
        <link rel="stylesheet" href="${pageContext.request.contextPath}/css/user-reg-edit.css" />
    </head>
    <body class="customer-theme">
        <%@ include file="/includes/header.jsp" %>
        <%@ include file="/includes/navbar.jsp" %>
        
        <div class="registration-container">
            <div class="registration-card">
                <div class="card-header customer">
                    <h2>
                        <i class="fa fa-edit role-icon"></i>
                        <span>Edit Customer Information</span>
                    </h2>
                </div>

                <div class="form-container">
                    <!-- Success Message -->
                    <% 
                    String successAttr = (String) request.getAttribute("success");
                    String successParam = request.getParameter("success");
                    if (successAttr != null || successParam != null) {
                        String successMessage = successAttr != null ? successAttr : 
                            ("customer_updated".equals(successParam) ? "Customer updated successfully!" : "Operation completed successfully!");
                    %>
                    <div class="alert alert-success">
                        <i class="fa fa-check-circle"></i>
                        <%= successMessage %>
                    </div>
                    <% }%>

                    <!-- Error Message -->
                    <% 
                    String errorAttr = (String) request.getAttribute("error");
                    String errorParam = request.getParameter("error");
                    if (errorAttr != null || errorParam != null) {
                        String errorMessage = errorAttr != null ? errorAttr : 
                            ("customer_exists".equals(errorParam) ? "A customer with this email already exists." : 
                            "invalid_data".equals(errorParam) ? "Please check your input data." : 
                            "database_error".equals(errorParam) ? "Database error occurred. Please try again." :
                            "An error occurred. Please try again.");
                    %>
                    <div class="alert alert-error">
                        <i class="fa fa-exclamation-triangle"></i>
                        <%= errorMessage %>
                    </div>
                    <% }%>

                    <form id="customerEditForm" method="post" enctype="multipart/form-data" action="${pageContext.request.contextPath}/CustomerServlet" novalidate>
                        <input type="hidden" name="action" value="update">
                        <input type="hidden" name="id" value="<%= customer.getId()%>">

                        <!-- Personal Information Section -->
                        <div class="form-row">
                            <div class="form-group">
                                <label for="name">Full Name <span class="required">*</span></label>
                                <input type="text" id="name" name="name" class="form-control customer" 
                                       value="<%= customer.getName()%>" 
                                       placeholder="Enter full name" required>
                                <div class="invalid-feedback"></div>
                            </div>

                            <div class="form-group">
                                <label for="email">Email Address <span class="required">*</span></label>
                                <input type="email" id="email" name="email" class="form-control customer" 
                                       value="<%= customer.getEmail()%>" 
                                       placeholder="customer@example.com" required>
                                <div class="invalid-feedback"></div>
                            </div>
                        </div>

                        <div class="form-group">
                            <label for="password">Password <span class="optional">(Leave blank to keep current password)</span></label>
                            <input type="password" id="password" name="password" class="form-control customer" 
                                   placeholder="Enter new password (minimum 6 characters)">
                            <div class="invalid-feedback"></div>
                        </div>

                        <div class="form-row">
                            <div class="form-group">
                                <label for="phone">Phone Number <span class="required">*</span></label>
                                <input type="tel" id="phone" name="phone" class="form-control customer" 
                                       value="<%= customer.getPhone() != null ? customer.getPhone() : ""%>" 
                                       placeholder="e.g., +60123456789" required>
                                <div class="invalid-feedback"></div>
                            </div>

                            <div class="form-group">
                                <label for="gender">Gender <span class="required">*</span></label>
                                <select id="gender" name="gender" class="form-control customer" required>
                                    <option value="" disabled>Select Gender</option>
                                    <option value="F" <%= "F".equals(customer.getGender()) ? "selected" : ""%>>Female</option>
                                    <option value="M" <%= "M".equals(customer.getGender()) ? "selected" : ""%>>Male</option>
                                </select>
                                <div class="invalid-feedback"></div>
                            </div>
                        </div>

                        <div class="form-group">
                            <label for="dob">Date of Birth <span class="required">*</span></label>
                            <input type="date" id="dob" name="dob" class="form-control customer" 
                                   value="<%= customer.getDob() != null ? customer.getDob().toString() : ""%>" 
                                   required style="line-height: normal">
                            <div class="invalid-feedback"></div>
                        </div>

                        <!-- Profile Picture Section -->
                        <div class="form-group">
                            <label for="profilePic">Profile Picture <span class="optional">(Optional)</span></label>
                            
                            <% if (customer.getProfilePic() != null && !customer.getProfilePic().isEmpty()) { %>
                            <% } %>

                            <div class="file-upload">
                                <div class="file-upload-wrapper">
                                    <input type="file" class="form-control" id="profilePic" name="profilePic" accept="image/*">
                                    <label for="profilePic" class="file-upload-btn" id="fileLabel">
                                        <i class="fa fa-cloud-upload"></i>
                                        <span>Choose New Profile Picture</span>
                                    </label>
                                </div>
                                <div class="invalid-feedback" style="display: block;"></div> <!-- Make sure it's visible -->
                                <small class="form-text text-muted">Leave empty to keep current picture. Accepted formats: JPG, PNG (Max size: 2MB)</small>
                            </div>
                        </div>

                        <div class="form-actions" style="display: flex; justify-content: space-between; align-items: center; margin-top: 30px;">
                            <a href="${pageContext.request.contextPath}/CustomerServlet?action=view&id=<%= customer.getId()%>" class="btn btn-secondary" style="text-decoration: none;">
                                <i class="fa fa-eye"></i> View Details
                            </a>
                            <div>
                                <a href="${pageContext.request.contextPath}/CustomerServlet?action=viewAll" class="btn btn-secondary" style="text-decoration: none; margin-right: 10px;">
                                    <i class="fa fa-arrow-left"></i> Back to List
                                </a>
                                <button type="submit" class="submit-btn customer" id="submitBtn">
                                    <span class="btn-text">
                                        <i class="fa fa-save"></i>
                                        Update Customer
                                    </span>
                                </button>
                            </div>
                        </div>
                    </form>
                </div>
            </div>
        </div>
        <%@ include file="/includes/footer.jsp" %>
        <%@ include file="/includes/scripts.jsp" %>

        <script src="${pageContext.request.contextPath}/js/jquery.min.js"></script>
        <script src="<%= request.getContextPath()%>/js/validate-register.js"></script>
        <script>
            $(document).ready(function () {
                console.log('Customer edit form validation loaded');
                
                // File input change handler
                $('#profilePic').change(function() {
                    const fileName = $(this).val().split('\\').pop();
                    if (fileName) {
                        $('#fileLabel span').text(fileName);
                    } else {
                        $('#fileLabel span').text('Choose New Profile Picture');
                    }
                });
            });
        </script>
    </body>
</html>
