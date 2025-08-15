<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="java.text.DecimalFormat" %>
<%@ page import="model.Doctor" %>
<%@ page import="model.Appointment" %>
<%@ page import="model.Customer" %>
<%@ page import="model.Treatment" %>
<%
    Doctor doctor = (Doctor) session.getAttribute("doctor");
    if (doctor == null) {
        response.sendRedirect("../login.jsp");
        return;
    }
    
    List<Appointment> appointments = (List<Appointment>) request.getAttribute("appointments");
    SimpleDateFormat dateFormat = (SimpleDateFormat) request.getAttribute("dateFormat");
    SimpleDateFormat timeFormat = (SimpleDateFormat) request.getAttribute("timeFormat");
    
    if (dateFormat == null) dateFormat = new SimpleDateFormat("dd MMM yyyy");
    if (timeFormat == null) timeFormat = new SimpleDateFormat("HH:mm");
    
    DecimalFormat currencyFormat = new DecimalFormat("#,##0.00");
%>

<!DOCTYPE html>
<html lang="en">
    <head>
        <title>Issue Payment - AMC Healthcare System</title>
        <%@ include file="/includes/head.jsp" %>
        <link rel="stylesheet" href="<%= request.getContextPath()%>/css/manager-homepage.css">
        <link rel="stylesheet" href="<%= request.getContextPath()%>/css/manage-staff.css">
        <link rel="stylesheet" href="<%= request.getContextPath()%>/css/doctor-ratings.css">
        <link rel="stylesheet" href="<%= request.getContextPath()%>/css/issue-payment.css">
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
                            <i class="fa fa-credit-card" style="color:white"></i>
                            <span style="color:white">Issue Payment</span>
                        </h1>
                        <p class="lead wow fadeInUp" data-wow-delay="0.2s" style="color: whitesmoke">
                            Create payment charges for completed appointments
                        </p>
                        <nav aria-label="breadcrumb" class="wow fadeInUp" data-wow-delay="0.3s">
                            <ol class="breadcrumb" style="background: transparent; margin: 0;">
                                <li class="breadcrumb-item">
                                    <a href="<%= request.getContextPath()%>/DoctorHomepageServlet" style="color: rgba(255,255,255,0.8);">Dashboard</a>
                                </li>
                                <li class="breadcrumb-item active" style="color: white;">Issue Payment</li>
                            </ol>
                        </nav>
                    </div>
                </div>
            </div>
        </section>

        <!-- MAIN CONTENT -->
        <section style="padding: 40px 0; background: #f5f5f5;">
            <div class="container">
                <!-- Error/Success Messages -->
                <% String error = (String) request.getAttribute("error"); %>
                <% String success = (String) request.getAttribute("success"); %>
                
                <% if (error != null) { %>
                <div class="alert alert-danger alert-dismissible wow fadeInUp">
                    <button type="button" class="close" data-dismiss="alert">&times;</button>
                    <i class="fa fa-exclamation-triangle"></i> <%= error %>
                </div>
                <% } %>
                
                <% if (success != null) { %>
                <div class="alert alert-success alert-dismissible wow fadeInUp">
                    <button type="button" class="close" data-dismiss="alert">&times;</button>
                    <i class="fa fa-check-circle"></i> <%= success %>
                </div>
                <% } %>

                <!-- Statistics Summary -->
                <div class="stats-summary wow fadeInUp" data-wow-delay="0.1s">
                    <h4>
                        <i class="fa fa-file-text"></i> 
                        <%= appointments != null ? appointments.size() : 0 %> Completed Appointments Ready for Payment
                    </h4>
                    <p>Set payment charges for completed appointments. Customers and counter staff will be notified of the amount to pay.</p>
                </div>

                <!-- Appointments List -->
                <% if (appointments != null && appointments.size() > 0) { %>
                    <% for (Appointment appointment : appointments) { %>
                    <div class="payment-card wow fadeInUp" data-wow-delay="0.2s">
                        <div class="appointment-header">
                            <div class="appointment-info">
                                <h5>
                                    <i class="fa fa-user"></i> 
                                    <%= appointment.getCustomer() != null ? appointment.getCustomer().getName() : "Unknown Patient" %>
                                </h5>
                                <div class="appointment-details">
                                    <div style="margin-bottom: 5px;">
                                        <i class="fa fa-calendar"></i> 
                                        <%= appointment.getAppointmentDate() != null ? dateFormat.format(appointment.getAppointmentDate()) : "N/A" %>
                                        &nbsp;&nbsp;
                                        <i class="fa fa-clock-o"></i> 
                                        <%= appointment.getAppointmentTime() != null ? timeFormat.format(appointment.getAppointmentTime()) : "N/A" %>
                                    </div>
                                    <div style="margin-bottom: 5px;">
                                        <i class="fa fa-stethoscope"></i> 
                                        <%= appointment.getTreatment() != null ? appointment.getTreatment().getName() : "N/A" %>
                                    </div>
                                    <% if (appointment.getCustomer() != null && appointment.getCustomer().getEmail() != null) { %>
                                    <div>
                                        <i class="fa fa-envelope"></i> 
                                        <%= appointment.getCustomer().getEmail() %>
                                    </div>
                                    <% } %>
                                </div>
                            </div>
                            <span class="status-badge">
                                <i class="fa fa-check"></i> Completed
                            </span>
                        </div>

                        <!-- Payment Form -->
                        <form method="post" action="<%= request.getContextPath()%>/DoctorServlet" class="payment-form">
                            <input type="hidden" name="action" value="createPayment">
                            <input type="hidden" name="appointmentId" value="<%= appointment.getId() %>">
                            
                            <div class="row">
                                <div class="col-md-12">
                                    <div class="form-group">
                                        <label for="amount_<%= appointment.getId() %>">
                                            <i class="fa fa-dollar"></i> Payment Amount (RM)
                                        </label>
                                      <input type="number" 
                                        class="form-control" 
                                        id="amount_<%= appointment.getId() %>" 
                                        name="amount" 
                                        placeholder="Enter amount (e.g., 150.00)" 
                                        required>
                                    </div>
                                </div>
                            </div>
                            
                            <div class="text-right">
                                <button type="submit" class="btn-issue-payment">
                                    <i class="fa fa-credit-card"></i> Issue Payment Charge
                                </button>
                            </div>
                        </form>
                    </div>
                    <% } %>
                <% } else { %>
                    <div class="no-appointments wow fadeInUp" data-wow-delay="0.2s">
                        <i class="fa fa-credit-card"></i>
                        <h4>No Appointments Available for Payment</h4>
                        <p>All completed appointments already have payment charges issued, or there are no completed appointments yet.</p>
                        <p style="margin-top: 20px;">
                            <a href="<%= request.getContextPath()%>/DoctorHomepageServlet" class="btn btn-secondary">
                                <i class="fa fa-arrow-left" style="font-size: small;"></i> Back to Dashboard
                            </a>
                        </p>
                    </div>
                <% } %>
            </div>
        </section>

        <%@ include file="/includes/footer.jsp" %>
        <%@ include file="/includes/scripts.jsp" %>

        <script>
            $(document).ready(function() {
                // Auto-focus on first amount field
                $('.form-control[name="amount"]:first').focus();
                
               // Format only on blur (when the user leaves the field)
                $('input[name="amount"]').on('blur', function() {
                    let value = $(this).val();
                    if (value && !isNaN(value)) {
                        $(this).val(parseFloat(value).toFixed(2));
                    }
                });
                
                // Form validation
                $('form').on('submit', function(e) {
                    let amount = $(this).find('input[name="amount"]').val();
                    
                    if (!amount || parseFloat(amount) <= 0) {
                        e.preventDefault();
                        alert('Please enter a valid payment amount greater than 0');
                        return false;
                    }
                    
                    if (parseFloat(amount) > 9999.99) {
                        e.preventDefault();
                        alert('Payment amount cannot exceed RM 9,999.99');
                        return false;
                    }
                    
                    // Confirm before submitting
                    let patientName = $(this).closest('.payment-card').find('.appointment-info h5').text().replace(/^\s*\S+\s+/, '');
                    if (!confirm('Issue payment charge of RM ' + parseFloat(amount).toFixed(2) + ' for ' + patientName + '?')) {
                        e.preventDefault();
                        return false;
                    }
                });
                
                // Add animations to payment cards
                $('.payment-card').hover(
                    function() {
                        $(this).find('.btn-issue-payment').addClass('pulse');
                    },
                    function() {
                        $(this).find('.btn-issue-payment').removeClass('pulse');
                    }
                );
            });
        </script>
    </body>
</html>
