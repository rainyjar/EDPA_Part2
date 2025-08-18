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
    System.out.print(customer);

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
            <a href="${pageContext.request.contextPath}/CustomerServlet?action=viewAll" class="back-btn" style="margin-top: 30px; margin-bottom: 30px">
                <i class="fa fa-arrow-left"></i> Back to Customer Management
            </a>

            <div class="registration-card">
                <div class="card-header customer">
                    <h2>
                        <i class="fa fa-edit role-icon"></i>
                        <span>Edit Customer Information</span>
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

                    <form id="customerForm" method="post" enctype="multipart/form-data"
                          action="${pageContext.request.contextPath}/CustomerServlet?action=update&id=${customer.id}" novalidate>
                        <input type="hidden" id="originalNric" name="originalNric" value="${customer.ic}">

                        <!-- Personal Information -->
                        <div class="form-row">
                            <div class="form-group">
                                <label for="name">Full Name <span class="required">*</span></label>
                                <input type="text" id="name" name="name" class="form-control customer"
                                       value="${customer.name}" placeholder="Enter full name" required>
                                <div class="invalid-feedback"></div>
                            </div>

                            <div class="form-group">
                                <label for="email">Email Address <span class="required">*</span></label>
                                <input type="email" id="email" name="email" class="form-control customer"
                                       value="${customer.email}" placeholder="customer@example.com" required>
                                <div class="invalid-feedback"></div>
                            </div>
                        </div>

                        <div class="form-row">
                            <div class="form-group">
                                <label for="password">Password <span class="required">*</span></label>
                                <input type="password" id="password" name="password" class="form-control customer"
                                       value="${customer.password}" placeholder="Minimum 6 characters" required>
                                <div class="invalid-feedback"></div>
                            </div>

                            <div class="form-group">
                                <label for="phone">Phone Number <span class="required">*</span></label>
                                <input type="tel" id="phone" name="phone" class="form-control customer"
                                       value="${customer.phone}" placeholder="e.g., 60123456789" required>
                                <div class="invalid-feedback"></div>
                            </div>
                        </div>

                        <div class="form-row">
                            <div class="form-group">
                                <label for="nric">NRIC <span class="required">*</span></label>
                                <input type="text" id="nric" name="nric" class="form-control customer" placeholder="xxxxxx-xx-xxxx"
                                       value="${customer != null ? customer.ic : ''}" required>
                                <div class="invalid-feedback" id="icError"></div>
                            </div>

                            <div class="form-group">
                                <label for="gender">Gender <span class="required">*</span></label>
                                <select id="gender" name="gender" class="form-control customer" required>
                                    <option value="" disabled ${customer.gender == null ? "selected" : ""}>Select Gender</option>
                                    <option value="F" ${customer.gender == 'F' ? "selected" : ""}>Female</option>
                                    <option value="M" ${customer.gender == 'M' ? "selected" : ""}>Male</option>
                                </select>
                                <div class="invalid-feedback"></div>
                            </div> 
                        </div>

                        <div class="form-group">
                            <label for="address">Address <span class="required">*</span></label>
                            <textarea id="address" name="address" class="form-control customer" style="resize: none;" rows="3" required>${customer != null ? customer.address : ''}</textarea>
                            <div class="invalid-feedback"></div>
                        </div>

                        <div class="form-group">
                            <label for="dob">Date of Birth <span class="required">*</span></label>
                            <input type="date" id="dob" name="dob" class="form-control customer"
                                   value="${customer.dob}" required style="line-height: normal">
                            <div class="invalid-feedback"></div>
                        </div>

                        <!-- Profile Picture -->
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

                        <button type="submit" class="submit-btn customer" id="submitBtn">
                            <span class="btn-text">
                                <i class="fa fa-save"></i>
                                Edit Customer
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
