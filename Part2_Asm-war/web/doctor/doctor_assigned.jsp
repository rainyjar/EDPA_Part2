<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*" %>
<%@ page import="java.text.*" %>
<%@ page import="model.*" %>
<%
    // Get data from request
    List<Appointment> appointments = (List<Appointment>) request.getAttribute("appointments");
    Doctor doctor = (Doctor) request.getAttribute("doctor");
    SimpleDateFormat dateFormat = (SimpleDateFormat) request.getAttribute("dateFormat");
    SimpleDateFormat timeFormat = (SimpleDateFormat) request.getAttribute("timeFormat");
    
    String successMsg = request.getParameter("success");
    String errorMsg = (String) request.getAttribute("error");
%>
<!DOCTYPE html>
<html lang="en">
    <head>
        <title>Assigned Appointments - APU Medical Center</title>
        <%@ include file="/includes/head.jsp" %>
        <link rel="stylesheet" href="<%= request.getContextPath()%>/css/doctor-homepage.css">
        <style>
            .appointment-card {
                border: 1px solid #ddd;
                border-radius: 8px;
                padding: 20px;
                margin-bottom: 20px;
                background: white;
                box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            }
            .appointment-header {
                display: flex;
                justify-content: space-between;
                align-items: center;
                margin-bottom: 15px;
                padding-bottom: 10px;
                border-bottom: 1px solid #eee;
            }
            .appointment-id {
                font-weight: bold;
                color: #667eea;
                font-size: 1.2em;
            }
            .status-badge {
                padding: 6px 12px;
                border-radius: 20px;
                font-size: 0.85em;
                font-weight: bold;
                text-transform: uppercase;
            }
            .status-approved { background: #d4edda; color: #155724; }
            .status-completed { background: #cce5ff; color: #004085; }
            .appointment-details {
                display: grid;
                grid-template-columns: 1fr 1fr;
                gap: 20px;
                margin-bottom: 20px;
            }
            .detail-item {
                display: flex;
                align-items: center;
                margin-bottom: 10px;
            }
            .detail-item i {
                margin-right: 10px;
                width: 20px;
                color: #667eea;
            }
            .completion-form {
                background: #f8f9fa;
                padding: 20px;
                border-radius: 8px;
                margin-top: 15px;
            }
            .form-row {
                display: flex;
                gap: 20px;
                margin-bottom: 15px;
            }
            .form-group {
                flex: 1;
            }
            .amount-input {
                position: relative;
            }
            .amount-input::before {
                content: "RM";
                position: absolute;
                left: 10px;
                top: 50%;
                transform: translateY(-50%);
                color: #666;
                z-index: 1;
            }
            .amount-input input {
                padding-left: 35px;
            }
            .validation-message {
                font-size: 0.85em;
                margin-top: 5px;
            }
            .validation-success { color: #28a745; }
            .validation-error { color: #dc3545; }
            .btn:disabled {
                opacity: 0.6;
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
                            <i class="fa fa-stethoscope" style="color:white"></i>
                            <span style="color:white">Assigned Appointments</span>
                        </h1>
                        <p class="lead wow fadeInUp" data-wow-delay="0.2s" style="color: whitesmoke">
                            Complete appointments and set treatment charges
                        </p>
                        <nav aria-label="breadcrumb" class="wow fadeInUp" data-wow-delay="0.3s">
                            <ol class="breadcrumb" style="background: transparent; margin: 0;">
                                <li class="breadcrumb-item">
                                    <a href="<%= request.getContextPath()%>/DoctorServlet?action=dashboard" style="color: rgba(255,255,255,0.8);">Dashboard</a> 
                                </li>
                                <li class="breadcrumb-item active" style="color: white;">Assigned Appointments</li>
                            </ol>
                        </nav>
                    </div>
                </div>
            </div>
        </section>

        <!-- MAIN CONTENT -->
        <section style="padding: 40px 0; background: #f5f5f5;">
            <div class="container">
                <!-- Success/Error Messages -->
                <% if (successMsg != null) { %>
                <div class="alert alert-success alert-dismissible wow fadeInUp">
                    <button type="button" class="close" data-dismiss="alert">&times;</button>
                    <i class="fa fa-check-circle"></i>
                    <%= successMsg %>
                </div>
                <% } %>

                <% if (errorMsg != null) { %>
                <div class="alert alert-danger alert-dismissible wow fadeInUp">
                    <button type="button" class="close" data-dismiss="alert">&times;</button>
                    <i class="fa fa-exclamation-triangle"></i>
                    <%= errorMsg %>
                </div>
                <% } %>

                <!-- APPOINTMENTS SECTION -->
                <div class="appointments-section wow fadeInUp" data-wow-delay="0.2s">
                    <div class="d-flex justify-content-between align-items-center mb-4">
                        <h3><i class="fa fa-list"></i> Your Assigned Appointments 
                            (<%= appointments != null ? appointments.size() : 0%>)
                        </h3>
                    </div>

                    <!-- Appointments List -->
                    <div class="appointments-list">
                        <% if (appointments != null && !appointments.isEmpty()) { %>
                            <% for (Appointment appointment : appointments) { 
                                String statusClass = "status-" + (appointment.getStatus() != null ? appointment.getStatus().toLowerCase() : "approved");
                                boolean isCompleted = "completed".equals(appointment.getStatus());
                                boolean canComplete = "approved".equals(appointment.getStatus());
                            %>
                            <div class="appointment-card">
                                <div class="appointment-header">
                                    <div class="appointment-id">
                                        Appointment #<%= appointment.getId() %>
                                    </div>
                                    <span class="status-badge <%= statusClass %>">
                                        <%= appointment.getStatus() != null ? appointment.getStatus().toUpperCase() : "APPROVED" %>
                                    </span>
                                </div>

                                <div class="appointment-details">
                                    <div class="details-left">
                                        <div class="detail-item">
                                            <i class="fa fa-user"></i>
                                            <strong>Patient:</strong>&nbsp;
                                            <%= appointment.getCustomer() != null ? appointment.getCustomer().getName() : "N/A" %>
                                        </div>
                                        
                                        <div class="detail-item">
                                            <i class="fa fa-envelope"></i>
                                            <strong>Email:</strong>&nbsp;
                                            <%= appointment.getCustomer() != null ? appointment.getCustomer().getEmail() : "N/A" %>
                                        </div>

                                        <div class="detail-item">
                                            <i class="fa fa-phone"></i>
                                            <strong>Phone:</strong>&nbsp;
                                            <%= appointment.getCustomer() != null ? appointment.getCustomer().getPhone() : "N/A" %>
                                        </div>

                                        <div class="detail-item">
                                            <i class="fa fa-stethoscope"></i>
                                            <strong>Treatment:</strong>&nbsp;
                                            <%= appointment.getTreatment() != null ? appointment.getTreatment().getName() : "N/A" %>
                                        </div>
                                    </div>

                                    <div class="details-right">
                                        <div class="detail-item">
                                            <i class="fa fa-calendar"></i>
                                            <strong>Date:</strong>&nbsp;
                                            <%= appointment.getAppointmentDate() != null ? dateFormat.format(appointment.getAppointmentDate()) : "N/A" %>
                                        </div>

                                        <div class="detail-item">
                                            <i class="fa fa-clock-o"></i>
                                            <strong>Time:</strong>&nbsp;
                                            <%= appointment.getAppointmentTime() != null ? timeFormat.format(appointment.getAppointmentTime()) : "N/A" %>
                                        </div>

                                        <div class="detail-item">
                                            <i class="fa fa-money"></i>
                                            <strong>Base Charge:</strong>&nbsp;
                                            RM <%= appointment.getTreatment() != null ? String.format("%.2f", appointment.getTreatment().getBaseConsultationCharge()) : "0.00" %>
                                        </div>

                                        <% if (appointment.getCustMessage() != null && !appointment.getCustMessage().trim().isEmpty()) { %>
                                        <div class="detail-item">
                                            <i class="fa fa-comment"></i>
                                            <strong>Patient Notes:</strong>&nbsp;
                                            <%= appointment.getCustMessage() %>
                                        </div>
                                        <% } %>
                                    </div>
                                </div>

                                <!-- Doctor Notes Display -->
                                <% if (isCompleted && appointment.getDocMessage() != null && !appointment.getDocMessage().trim().isEmpty()) { %>
                                <div class="alert alert-info">
                                    <strong>Doctor Notes:</strong> <%= appointment.getDocMessage() %>
                                </div>
                                <% } %>

                                <!-- Completion Form -->
                                <% if (canComplete) { %>
                                <div class="completion-form">
                                    <h5><i class="fa fa-check-circle"></i> Complete Appointment</h5>
                                    <form id="completionForm<%= appointment.getId() %>" method="post" action="<%= request.getContextPath()%>/PaymentServlet">
                                        <input type="hidden" name="action" value="completeAppointment">
                                        <input type="hidden" name="appointmentId" value="<%= appointment.getId() %>">
                                        
                                        <div class="form-row">
                                            <div class="form-group">
                                                <label for="doctorNotes<%= appointment.getId() %>">Doctor Notes (Optional):</label>
                                                <textarea class="form-control" name="doctorNotes" id="doctorNotes<%= appointment.getId() %>" 
                                                         rows="3" placeholder="Enter your notes about the treatment..."></textarea>
                                            </div>
                                        </div>
                                        
                                        <div class="form-row">
                                            <div class="form-group">
                                                <label for="paymentAmount<%= appointment.getId() %>">Treatment Charges (RM): *</label>
                                                <div class="amount-input">
                                                    <input type="number" class="form-control" name="paymentAmount" 
                                                           id="paymentAmount<%= appointment.getId() %>" 
                                                           min="0" step="0.01" 
                                                           value="<%= appointment.getTreatment() != null ? String.format("%.2f", appointment.getTreatment().getBaseConsultationCharge()) : "0.00" %>"
                                                           required onblur="validateAmount(<%= appointment.getId() %>)">
                                                </div>
                                                <div id="amountValidation<%= appointment.getId() %>" class="validation-message"></div>
                                            </div>
                                        </div>
                                        
                                        <div class="text-center">
                                            <button type="button" class="btn btn-success" id="completeBtn<%= appointment.getId() %>" 
                                                    onclick="confirmCompletion(<%= appointment.getId() %>)" disabled>
                                                <i class="fa fa-check"></i> Mark as Completed & Send Charges
                                            </button>
                                        </div>
                                    </form>
                                </div>
                                <% } else if (isCompleted) { %>
                                <div class="alert alert-success">
                                    <i class="fa fa-check-circle"></i> This appointment has been completed and charges have been sent to counter staff.
                                </div>
                                <% } %>
                            </div>
                            <% } %>
                        <% } else { %>
                        <div class="no-data text-center">
                            <i class="fa fa-calendar-times-o" style="font-size: 4em; color: #ccc; margin-bottom: 20px;"></i>
                            <h4>No Assigned Appointments</h4>
                            <p>You don't have any assigned appointments at the moment.</p>
                        </div>
                        <% } %>
                    </div>
                </div>
            </div>
        </section>

        <%@ include file="/includes/footer.jsp" %>
        <%@ include file="/includes/scripts.jsp" %>

        <script>
            function validateAmount(appointmentId) {
                const input = document.getElementById('paymentAmount' + appointmentId);
                const validation = document.getElementById('amountValidation' + appointmentId);
                const button = document.getElementById('completeBtn' + appointmentId);
                
                const amount = parseFloat(input.value);
                
                if (isNaN(amount) || amount < 0) {
                    validation.innerHTML = '<i class="fa fa-times"></i> Amount must be a positive number';
                    validation.className = 'validation-message validation-error';
                    button.disabled = true;
                } else if (amount > 99999.99) {
                    validation.innerHTML = '<i class="fa fa-times"></i> Amount cannot exceed RM 99,999.99';
                    validation.className = 'validation-message validation-error';
                    button.disabled = true;
                } else {
                    // Check decimal places
                    const decimalPlaces = (amount.toString().split('.')[1] || []).length;
                    if (decimalPlaces > 2) {
                        validation.innerHTML = '<i class="fa fa-times"></i> Maximum 2 decimal places allowed';
                        validation.className = 'validation-message validation-error';
                        button.disabled = true;
                    } else {
                        validation.innerHTML = '<i class="fa fa-check"></i> Valid amount: RM ' + amount.toFixed(2);
                        validation.className = 'validation-message validation-success';
                        button.disabled = false;
                    }
                }
            }
            
            function confirmCompletion(appointmentId) {
                const amount = document.getElementById('paymentAmount' + appointmentId).value;
                const formattedAmount = parseFloat(amount).toFixed(2);
                
                if (confirm('Are you sure you want to mark this appointment as completed and send charges of RM ' + formattedAmount + ' to counter staff?')) {
                    document.getElementById('completionForm' + appointmentId).submit();
                }
            }
            
            // Initialize validation on page load
            window.onload = function() {
                <% if (appointments != null) { %>
                    <% for (Appointment appointment : appointments) { %>
                        <% if ("approved".equals(appointment.getStatus())) { %>
                            validateAmount(<%= appointment.getId() %>);
                        <% } %>
                    <% } %>
                <% } %>
            };
        </script>
    </body>
</html>
