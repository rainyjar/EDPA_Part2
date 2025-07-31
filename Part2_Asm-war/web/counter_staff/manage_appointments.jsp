<%@page import="model.Appointment"%>
<%@page import="model.CounterStaff"%>
<%@page import="model.Customer"%>
<%@page import="model.Doctor"%>
<%@page import="model.Treatment"%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="java.util.Date" %>

<%
    // Check if counter staff is logged in
    CounterStaff loggedInStaff = (CounterStaff) session.getAttribute("staff");

    if (loggedInStaff == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    // Retrieve appointment data from request attributes
    List<Appointment> appointmentList = (List<Appointment>) request.getAttribute("appointmentList");
    List<Doctor> doctorList = (List<Doctor>) request.getAttribute("doctorList");
    List<Treatment> treatmentList = (List<Treatment>) request.getAttribute("treatmentList");
    List<CounterStaff> staffList = (List<CounterStaff>) request.getAttribute("staffList");

    // Get search/filter parameters
    String searchQuery = request.getParameter("search");
    String statusFilter = request.getParameter("status");
    String doctorFilter = request.getParameter("doctor");
    String treatmentFilter = request.getParameter("treatment");
    String staffFilter = request.getParameter("staff");
    String dateFilter = request.getParameter("date");

    if (searchQuery == null) searchQuery = "";
    if (statusFilter == null) statusFilter = "all";
    if (doctorFilter == null) doctorFilter = "all";
    if (treatmentFilter == null) treatmentFilter = "all";
    if (staffFilter == null) staffFilter = "all";
    if (dateFilter == null) dateFilter = "";

    // Get success/error messages
    String successMsg = request.getParameter("success");
    String errorMsg = request.getParameter("error");

    SimpleDateFormat dateFormat = new SimpleDateFormat("dd MMM yyyy");
    SimpleDateFormat timeFormat = new SimpleDateFormat("HH:mm");
%>

<!DOCTYPE html>
<html lang="en">
    <head>
        <title>Manage Appointments - APU Medical Center</title>
        <%@ include file="/includes/head.jsp" %>
        <link rel="stylesheet" href="<%= request.getContextPath()%>/css/manager-homepage.css">
        <link rel="stylesheet" href="<%= request.getContextPath()%>/css/manage-staff.css">
        <style>

            .appointment-card {
                border: 1px solid #ddd;
                border-radius: 8px;
                padding: 15px;
                margin-bottom: 15px;
                background: white;
                box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            }
            .appointment-header {
                display: flex;
                justify-content: between;
                align-items: center;
                margin-bottom: 10px;
            }
            .appointment-id {
                font-weight: bold;
                color: #667eea;
                font-size: 1.1em;
            }
            .status-badge {
                padding: 4px 12px;
                border-radius: 20px;
                font-size: 0.85em;
                font-weight: bold;
                text-transform: uppercase;
            }
            .status-pending { background: #fff3cd; color: #856404; }
            .status-approved { background: #d4edda; color: #155724; }
            .status-completed { background: #cce5ff; color: #004085; }
            .status-cancelled { background: #f8d7da; color: #721c24; }
            .status-overdue { background: #f5c6cb; color: #721c24; }
            .status-reschedule { background: #ffeaa7; color: #6c5502; }
            .appointment-details {
                display: grid;
                grid-template-columns: 1fr 1fr;
                gap: 15px;
                margin-bottom: 15px;
            }
            .detail-item {
                display: flex;
                align-items: center;
            }
            .detail-item i {
                margin-right: 8px;
                width: 16px;
                color: #667eea;
            }
            .appointment-actions {
                display: flex;
                gap: 8px;
                flex-wrap: wrap;
            }
            .btn-sm {
                padding: 4px 8px;
                font-size: 0.8em;
            }
            .search-filters {
                background: white;
                padding: 20px;
                border-radius: 8px;
                margin-bottom: 20px;
                box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            }
            .filter-row {
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
                gap: 15px;
                margin-bottom: 15px;
            }
            .modal {
                z-index: 1050;
            }
            .modal-backdrop {
                z-index: 1040;
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
                            <i class="fa fa-calendar-check-o" style="color:white"></i>
                            <span style="color:white">Manage Appointments</span>
                        </h1>
                        <p class="lead wow fadeInUp" data-wow-delay="0.2s" style="color: whitesmoke">
                            View, search, reschedule, and manage all appointments
                        </p>
                        <nav aria-label="breadcrumb" class="wow fadeInUp" data-wow-delay="0.3s">
                            <ol class="breadcrumb" style="background: transparent; margin: 0;">
                                <li class="breadcrumb-item">
                                    <a href="<%= request.getContextPath()%>/CounterStaffServlet?action=dashboard" style="color: rgba(255,255,255,0.8);">Dashboard</a> 
                                </li>
                                <li class="breadcrumb-item active" style="color: white;">Manage Appointments</li>
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
                    <% if ("appointment_rescheduled".equals(successMsg)) { %>
                    Appointment rescheduled successfully!
                    <% } else if ("appointment_cancelled".equals(successMsg)) { %>
                    Appointment cancelled successfully!
                    <% } else if ("doctor_assigned".equals(successMsg)) { %>
                    Doctor assigned to appointment successfully!
                    <% } else if ("status_updated".equals(successMsg)) { %>
                    Appointment status updated successfully!
                    <% } else if ("reschedule_requested".equals(successMsg)) { %>
                    Reschedule request sent successfully!
                    <% } else { %>
                    Operation completed successfully!
                    <% } %>
                </div>
                <% } %>

                <% if (errorMsg != null) { %>
                <div class="alert alert-danger alert-dismissible wow fadeInUp">
                    <button type="button" class="close" data-dismiss="alert">&times;</button>
                    <i class="fa fa-exclamation-triangle"></i>
                    <% if ("appointment_not_found".equals(errorMsg)) { %>
                    Appointment not found. It may have been deleted or modified.
                    <% } else if ("invalid_status".equals(errorMsg)) { %>
                    Invalid appointment status for this operation.
                    <% } else if ("doctor_unavailable".equals(errorMsg)) { %>
                    Selected doctor is not available at the requested time.
                    <% } else if ("invalid_data".equals(errorMsg)) { %>
                    Please check all required fields and try again.
                    <% } else if ("permission_denied".equals(errorMsg)) { %>
                    You don't have permission to perform this action.
                    <% } else { %>
                    An error occurred. Please try again.
                    <% } %>
                </div>
                <% } %>

                <!-- Info Message for No Results -->
                <% 
                String infoMessage = (String) request.getAttribute("infoMessage");
                if (infoMessage != null) { %>
                <div class="alert alert-info alert-dismissible wow fadeInUp">
                    <button type="button" class="close" data-dismiss="alert">&times;</button>
                    <i class="fa fa-info-circle"></i>
                    <%= infoMessage %>
                </div>
                <% } %>

                <!-- SEARCH AND FILTER SECTION -->
                <div class="search-filters wow fadeInUp" data-wow-delay="0.2s">
                    <h3><i class="fa fa-search"></i> Search & Filter Appointments</h3>

                    <form method="GET" action="<%= request.getContextPath()%>/AppointmentServlet" class="search-form">
                        <input type="hidden" name="action" value="manage">

                        <div class="filter-row">
                            <div class="form-group">
                                <label for="search">Search by Customer/ID</label>
                                <input type="text" class="form-control" id="search" name="search" 
                                       value="<%= searchQuery%>" placeholder="Customer name, email, or appointment ID...">
                            </div>

                            <div class="form-group">
                                <label for="status">Filter by Status</label>
                                <select class="form-control" id="status" name="status">
                                    <option value="all" <%= "all".equals(statusFilter) ? "selected" : ""%>>All Statuses</option>
                                    <option value="pending" <%= "pending".equals(statusFilter) ? "selected" : ""%>>Pending</option>
                                    <option value="approved" <%= "approved".equals(statusFilter) ? "selected" : ""%>>Approved</option>
                                    <option value="completed" <%= "completed".equals(statusFilter) ? "selected" : ""%>>Completed</option>
                                    <option value="cancelled" <%= "cancelled".equals(statusFilter) ? "selected" : ""%>>Cancelled</option>
                                    <option value="overdue" <%= "overdue".equals(statusFilter) ? "selected" : ""%>>Overdue</option>
                                    <option value="reschedule" <%= "reschedule".equals(statusFilter) ? "selected" : ""%>>Reschedule Required</option>
                                </select>
                            </div>

                            <div class="form-group">
                                <label for="doctor">Filter by Doctor</label>
                                <select class="form-control" id="doctor" name="doctor">
                                    <option value="all" <%= "all".equals(doctorFilter) ? "selected" : ""%>>All Doctors</option>
                                    <% if (doctorList != null) {
                                        for (Doctor doctor : doctorList) { %>
                                    <option value="<%= doctor.getId() %>" <%= String.valueOf(doctor.getId()).equals(doctorFilter) ? "selected" : ""%>>
                                        Dr. <%= doctor.getName() %>
                                    </option>
                                    <% } } %>
                                </select>
                            </div>
                        </div>

                        <div class="filter-row">
                            <div class="form-group">
                                <label for="treatment">Filter by Treatment</label>
                                <select class="form-control" id="treatment" name="treatment">
                                    <option value="all" <%= "all".equals(treatmentFilter) ? "selected" : ""%>>All Treatments</option>
                                    <% if (treatmentList != null) {
                                        for (Treatment treatment : treatmentList) { %>
                                    <option value="<%= treatment.getId() %>" <%= String.valueOf(treatment.getId()).equals(treatmentFilter) ? "selected" : ""%>>
                                        <%= treatment.getName() %>
                                    </option>
                                    <% } } %>
                                </select>
                            </div>

                            <div class="form-group">
                                <label for="staff">Filter by Counter Staff</label>
                                <select class="form-control" id="staff" name="staff">
                                    <option value="all" <%= "all".equals(staffFilter) ? "selected" : ""%>>All Staff</option>
                                    <option value="not_assigned" <%= "not_assigned".equals(staffFilter) ? "selected" : ""%>>Not Assigned</option>
                                    <% if (staffList != null) {
                                        for (CounterStaff staff : staffList) { %>
                                    <option value="<%= staff.getId() %>" <%= String.valueOf(staff.getId()).equals(staffFilter) ? "selected" : ""%>>
                                        <%= staff.getName() %>
                                    </option>
                                    <% } } %>
                                </select>
                            </div>

                            <div class="form-group">
                                <label for="date">Filter by Date</label>
                                <input type="date" class="form-control" id="date" name="date" value="<%= dateFilter %>">
                            </div>
                        </div>

                        <div class="text-center">
                            <button type="submit" class="btn btn-primary">
                                <i class="fa fa-search"></i> Search & Filter
                            </button>
                            <a href="<%= request.getContextPath()%>/AppointmentServlet?action=manage" class="btn btn-secondary">
                                <i class="fa fa-refresh"></i> Reset
                            </a>
                        </div>
                    </form>
                </div>

                <!-- APPOINTMENTS SECTION -->
                <div class="appointments-section wow fadeInUp" data-wow-delay="0.4s">
                    <div class="d-flex justify-content-between align-items-center mb-4">
                        <h3><i class="fa fa-list"></i> Appointments 
                            (<%= appointmentList != null ? appointmentList.size() : 0%>)
                        </h3>
                    </div>

                    <!-- Appointments List -->
                    <div class="appointments-list">
                        <% if (appointmentList != null && !appointmentList.isEmpty()) { %>
                            <% for (Appointment appointment : appointmentList) { 
                                String statusClass = "status-" + (appointment.getStatus() != null ? appointment.getStatus().toLowerCase() : "pending");
                                if ("reschedule required".equals(appointment.getStatus())) {
                                    statusClass = "status-reschedule";
                                }
                            %>
                            <div class="appointment-card">
                                <div class="appointment-header">
                                    <div class="appointment-id">
                                        Appointment #<%= appointment.getId() %>
                                    </div>
                                    <span class="status-badge <%= statusClass %>">
                                        <%= appointment.getStatus() != null ? appointment.getStatus().toUpperCase() : "PENDING" %>
                                    </span>
                                </div>

                                <div class="appointment-details">
                                    <div class="detail-item">
                                        <i class="fa fa-user"></i>
                                        <strong>Patient:</strong>&nbsp;
                                        <%= appointment.getCustomer() != null ? appointment.getCustomer().getName() : "N/A" %>
                                        <% if (appointment.getCustomer() != null) { %>
                                        <small class="text-muted">(ID: <%= appointment.getCustomer().getId() %>)</small>
                                        <% } %>
                                    </div>
                                    
                                    <div class="detail-item">
                                        <i class="fa fa-stethoscope"></i>
                                        <strong>Treatment:</strong>&nbsp;
                                        <%= appointment.getTreatment() != null ? appointment.getTreatment().getName() : "N/A" %>
                                    </div>

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
                                        <i class="fa fa-user-md"></i>
                                        <strong>Doctor:</strong>&nbsp;
                                        <%= appointment.getDoctor() != null ? "Dr. " + appointment.getDoctor().getName() : "Not Assigned" %>
                                    </div>

                                    <div class="detail-item">
                                        <i class="fa fa-user-circle"></i>
                                        <strong>Handled by:</strong>&nbsp;
                                        <%= appointment.getCounterStaff() != null ? appointment.getCounterStaff().getName() : "Not Assigned" %>
                                    </div>
                                </div>

                                <!-- Messages Section -->
                                <% if (appointment.getCustMessage() != null && !appointment.getCustMessage().trim().isEmpty()) { %>
                                <div style="margin-bottom: 10px;">
                                    <small><strong>Customer Message:</strong> <%= appointment.getCustMessage() %></small>
                                </div>
                                <% } %>

                                <% if (appointment.getStaffMessage() != null && !appointment.getStaffMessage().trim().isEmpty()) { %>
                                <div style="margin-bottom: 10px;">
                                    <small><strong>Staff Notes:</strong> <%= appointment.getStaffMessage() %></small>
                                </div>
                                <% } %>

                                <!-- Action Buttons -->
                                <div class="appointment-actions">
                                    <% 
                                    String status = appointment.getStatus();
                                    boolean isCompleted = "completed".equals(status);
                                    boolean isCancelled = "cancelled".equals(status);
                                    boolean isPending = "pending".equals(status);
                                    boolean isRescheduleRequired = "reschedule required".equals(status);
                                    %>

                                    <!-- Reschedule Appointment -->
                                    <% if ("pending".equals(status) || "reschedule required".equals(status) || 
                                           "approved".equals(status) || "overdue".equals(status)) { %>
                                    <button class="btn btn-warning btn-sm" onclick="rescheduleAppointment(<%= appointment.getId() %>)">
                                        <i class="fa fa-calendar"></i> Reschedule
                                    </button>
                                    <% } %>

                                    <!-- Require Reschedule -->
                                    <% if (!isCompleted && !isCancelled && !isRescheduleRequired) { %>
                                    <button class="btn btn-info btn-sm" onclick="requireReschedule(<%= appointment.getId() %>)">
                                        <i class="fa fa-exclamation-triangle"></i> Require Reschedule
                                    </button>
                                    <% } %>

                                    <!-- Cancel Appointment -->
                                    <% if (!isCompleted && !isCancelled) { %>
                                    <button class="btn btn-danger btn-sm" onclick="cancelAppointment(<%= appointment.getId() %>)">
                                        <i class="fa fa-times"></i> Cancel
                                    </button>
                                    <% } %>

                                    <!-- Assign Doctor -->
                                    <% if (isPending) { %>
                                    <button class="btn btn-success btn-sm assign-doctor-btn" 
                                            data-appointment-id="<%= appointment.getId() %>"
                                            data-preferred-doctor="<%= appointment.getDoctor() != null ? appointment.getDoctor().getName() : "Not specified" %>"
                                            data-doctor-id="<%= appointment.getDoctor() != null ? appointment.getDoctor().getId() : "" %>">
                                        <i class="fa fa-user-md"></i> Assign Doctor
                                    </button>
                                    <% } %>

                                    <!-- View Details -->
                                    <button class="btn btn-primary btn-sm" onclick="viewAppointment(<%= appointment.getId() %>)">
                                        <i class="fa fa-eye"></i> View Details
                                    </button>
                                </div>
                            </div>
                            <% } %>
                        <% } else { %>
                        <div class="no-data">
                            <i class="fa fa-calendar-times-o"></i>
                            <h4>No Appointments Found</h4>
                            <p>No appointments match your search criteria.</p>
                            </a>
                        </div>
                        <% } %>
                    </div>
                </div>
            </div>
        </section>

        <!-- Require Reschedule Modal -->
        <div class="modal fade" id="requireRescheduleModal" tabindex="-1" role="dialog">
            <div class="modal-dialog" role="document">
                <div class="modal-content">
                    <div class="modal-header">
                        <h4 class="modal-title">
                            <i class="fa fa-exclamation-triangle"></i> Require Appointment Reschedule
                        </h4>
                        <button type="button" class="close" data-dismiss="modal">&times;</button>
                    </div>
                    <form id="requireRescheduleForm" method="post" action="<%= request.getContextPath()%>/AppointmentServlet">
                        <div class="modal-body">
                            <input type="hidden" name="action" value="requireReschedule">
                            <input type="hidden" name="appointmentId" id="requireRescheduleAppointmentId">
                            
                            <div class="form-group">
                                <label for="rescheduleReason">Reason for Reschedule Request:</label>
                                <textarea class="form-control" name="staffMessage" id="rescheduleReason" 
                                         rows="4" required placeholder="Please explain why this appointment needs to be rescheduled..."></textarea>
                            </div>
                            
                            <div class="alert-info">
                                <i class="fa fa-info-circle"></i>
                                This will change the appointment status to "Reschedule Required" and notify the customer.</small>
                            </div>
                        </div>
                        <div class="modal-footer">
                            <button type="submit" class="btn btn-warning">
                                <i class="fa fa-exclamation-triangle"></i> Request Reschedule
                            </button>
                            <button type="button" class="btn btn-secondary" data-dismiss="modal">Cancel</button>
                        </div>
                    </form>
                </div>
            </div>
        </div>

        <!-- Cancel Appointment Modal -->
        <div class="modal fade" id="cancelAppointmentModal" tabindex="-1" role="dialog">
            <div class="modal-dialog" role="document">
                <div class="modal-content">
                    <div class="modal-header">
                        <h4 class="modal-title">
                            <i class="fa fa-times"></i> Cancel Appointment
                        </h4>
                        <button type="button" class="close" data-dismiss="modal">&times;</button>
                    </div>
                    <form id="cancelAppointmentForm" method="post" action="<%= request.getContextPath()%>/AppointmentServlet">
                        <div class="modal-body">
                            <input type="hidden" name="action" value="cancel">
                            <input type="hidden" name="appointmentId" id="cancelAppointmentId">
                            
                            <div class="form-group">
                                <label for="cancellationReason">Cancellation Reason:</label>
                                <textarea class="form-control" name="staffMessage" id="cancellationReason" 
                                         rows="4" required placeholder="Please explain the reason for cancellation..."></textarea>
                            </div>
                            
                            <div class="alert-info">
                                <i class="fa fa-info-circle"></i>
                                <strong>Warning:</strong> This action cannot be undone. The appointment will be permanently cancelled.
                            </div>
                        </div>
                        <div class="modal-footer">
                            <button type="submit" class="btn btn-danger">
                                <i class="fa fa-times"></i> Cancel Appointment
                            </button>
                            <button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
                        </div>
                    </form>
                </div>
            </div>
        </div>

        <!-- Assign Doctor Modal -->
        <div class="modal fade" id="assignDoctorModal" tabindex="-1" role="dialog">
            <div class="modal-dialog" role="document">
                <div class="modal-content">
                    <div class="modal-header">
                        <h4 class="modal-title">
                            <i class="fa fa-user-md"></i> Assign Doctor to Appointment
                        </h4>
                        <button type="button" class="close" data-dismiss="modal">&times;</button>
                    </div>
                    <form id="assignDoctorForm" method="post" action="<%= request.getContextPath()%>/AppointmentServlet">
                        <div class="modal-body">
                            <input type="hidden" name="action" value="assignDoctor">
                            <input type="hidden" name="appointmentId" id="assignDoctorAppointmentId">
                            <input type="hidden" name="doctorId" id="assignDoctorDoctorId">

                            <!-- Display Requested Doctor -->
                            <div class="form-group">
                                <label for="preferredDoctor">Requested Doctor:</label>
                                <input type="text" class="form-control" id="preferredDoctor" name="preferredDoctor" readonly>
                                <small id="doctorAvailabilityWarning" class="text-danger" style="display: none;">
                                    <i class="fa fa-exclamation-triangle"></i> This doctor is unavailable for the selected date.
                                </small>
                            </div>

                            <!-- Assignment Notes -->
                            <div class="form-group">
                                <label for="assignmentNotes">Assignment Notes to Customer (Optional):</label>
                                <textarea class="form-control" name="staffMessage" id="assignmentNotes" 
                                          rows="3" placeholder="Any notes about this doctor assignment..."></textarea>
                            </div>
                        </div>
                        <div class="modal-footer">
                            <!-- Action Buttons -->
                            <button type="submit" class="btn btn-success" id="confirmAssignButton" disabled>
                                <i class="fa fa-check"></i> Confirm & Assign
                            </button>
                            <button type="button" class="btn btn-warning" onclick="rejectAndReschedule()">
                                <i class="fa fa-exclamation-triangle"></i> Reject & Mark Reschedule Required
                            </button>
                            <button type="button" class="btn btn-secondary" data-dismiss="modal">Cancel</button>
                        </div>
                    </form>
                </div>
            </div>
        </div>

        <!-- View Appointment Details Modal -->
        <div class="modal fade" id="viewDetailsModal" tabindex="-1" role="dialog">
            <div class="modal-dialog modal-lg" role="document">
                <div class="modal-content">
                    <div class="modal-header bg-primary text-white">
                        <h4 class="modal-title" style="color: #ffffff;">
                            <i class="fa fa-eye"></i> Appointment Details #<span id="view-appointment-id"></span><br>
                            <span id="view-appointment-status" class="status-badge"></span>
                        </h4>
                    </div>
                    <div class="modal-body">
                        <!-- Appointment Status Details -->                       
                        <div class="row">
                            <div class="col-md-6">
                                <div class="card border-info mb-3">
                                    <div class="card-header bg-info text-white">
                                        <h6 class="mb-0"><i class="fa fa-user"></i> Patient Information</h6>
                                    </div>
                                    <div class="card-body">
                                        <p><strong>Name:</strong> <span id="view-customer-name" class="text-primary"></span></p>
                                        <p><strong>Email:</strong> <span id="view-customer-email"></span></p>
                                        <p><strong>Phone:</strong> <span id="view-customer-phone"></span></p>
                                        <p><strong>Gender:</strong> <span id="view-customer-gender"></span></p>
                                    </div>
                                </div>
                            </div>
                            <div class="col-md-6">
                                <div class="card border-success mb-3">
                                    <div class="card-header bg-success text-white">
                                        <h6 class="mb-0"><i class="fa fa-calendar"></i> Appointment Information</h6>
                                    </div>
                                    <div class="card-body">
                                        <p><strong>Date:</strong> <span id="view-appointment-date" class="text-success"></span></p>
                                        <p><strong>Time:</strong> <span id="view-appointment-time" class="text-success"></span></p>
                                        <p><strong>Duration:</strong> <span class="text-muted">30 minutes</span></p>                                    </div>
                                </div>
                            </div>
                        </div>
                        
                        <div class="row">
                            <div class="col-md-6">
                                <div class="card border-warning mb-3">
                                    <div class="card-header bg-warning text-dark">
                                        <h6 class="mb-0"><i class="fa fa-stethoscope"></i> Treatment & Doctor</h6>
                                    </div>
                                    <div class="card-body">
                                        <p><strong>Treatment:</strong> <span id="view-treatment-name" class="text-warning"></span></p>
                                        <p><strong>Doctor:</strong> <span id="view-doctor-name" class="text-primary"></span></p>
                                        <p><strong>Specialization:</strong> <span id="view-doctor-spec"></span></p>
                                        <p><strong>Charge: </strong> <span id="view-treatment-price" class="text-success">RM <span>0.00</span></span></p>
                                    </div>
                                </div>
                            </div>
                            <div class="col-md-6">
                                <div class="card border-secondary mb-3">
                                    <div class="card-header bg-danger text-white">
                                        <h6 class="mb-0"><i class="fa fa-user-circle"></i> Staff Information</h6>
                                    </div>
                                    <div class="card-body">
                                        <p><strong>Handled by:</strong> <span id="view-staff-name" class="text-danger"></span></p>
                                        <p><strong>Role:</strong> <span class="text-muted">Counter Staff</span></p>
                                        <p><strong>Contact:</strong> <span id="view-staff-contact">Available during office hours</span></p>
                                    </div>
                                </div>
                            </div>
                        </div>
                        
                        <!-- Messages Section -->
                        <div class="card border-light">
                            <div class="card-header bg-light">
                                <h6 class="mb-0"><i class="fa fa-comments"></i> Messages & Notes</h6>
                            </div>
                            <div class="card-body">
                                <div class="row">
                                    <div class="col-md-4">
                                        <div class="form-group">
                                            <label class="font-weight-bold text-info"><i class="fa fa-user"></i> Customer Message:</label>
                                            <div id="view-customer-message" class="border rounded p-2 bg-light" style="min-height: 60px; font-style: italic;"></div>
                                        </div>
                                    </div>
                                    <div class="col-md-4">
                                        <div class="form-group">
                                            <label class="font-weight-bold text-success"><i class="fa fa-user-md"></i> Doctor Message:</label>
                                            <div id="view-doctor-message" class="border rounded p-2 bg-light" style="min-height: 60px; font-style: italic;"></div>
                                        </div>
                                    </div>
                                    <div class="col-md-4">
                                        <div class="form-group">
                                            <label class="font-weight-bold text-warning"><i class="fa fa-sticky-note"></i> Staff Notes:</label>
                                            <div id="view-staff-message" class="border rounded p-2 bg-light" style="min-height: 60px; font-style: italic;"></div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                        
                        <!-- Quick Actions -->
                        <div class="text-center mt-3">
                            <button type="button" class="btn btn-warning btn-sm" onclick="$('#viewDetailsModal').modal('hide'); rescheduleAppointment($('#view-appointment-id').text());">
                                <i class="fa fa-calendar"></i> Reschedule
                            </button>
                            <button type="button" class="btn btn-info btn-sm" onclick="$('#viewDetailsModal').modal('hide'); requireReschedule($('#view-appointment-id').text());">
                                <i class="fa fa-exclamation-triangle"></i> Require Reschedule
                            </button>
                            <button type="button" class="btn btn-danger btn-sm" onclick="$('#viewDetailsModal').modal('hide'); cancelAppointment($('#view-appointment-id').text());">
                                <i class="fa fa-times"></i> Cancel
                            </button>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-dismiss="modal">
                            <i class="fa fa-times"></i> Close
                        </button>
                    </div>
                </div>
            </div>
        </div>

        <%@ include file="/includes/footer.jsp" %>
        <%@ include file="/includes/scripts.jsp" %>

        <script>
            // Action Functions
            function rescheduleAppointment(appointmentId) {
                window.location.href = '<%= request.getContextPath()%>/AppointmentServlet?action=rescheduleStaff&appointmentId=' + appointmentId;
            }

            function requireReschedule(appointmentId) {
                $('#requireRescheduleAppointmentId').val(appointmentId);
                $('#requireRescheduleModal').modal('show');
            }

            function cancelAppointment(appointmentId) {
                $('#cancelAppointmentId').val(appointmentId);
                $('#cancelAppointmentModal').modal('show');
            }

            function assignDoctor(appointmentId) {
                $('#assignDoctorAppointmentId').val(appointmentId);
                $('#assignDoctorModal').modal('show');
            }

            // Event handler for assign doctor buttons using data attributes
            $(document).on('click', '.assign-doctor-btn', function() {
                const appointmentId = $(this).data('appointment-id');
                const preferredDoctor = $(this).data('preferred-doctor');
                const doctorId = $(this).data('doctor-id');
                
                $('#assignDoctorAppointmentId').val(appointmentId);
                $('#assignDoctorDoctorId').val(doctorId);
                $('#preferredDoctor').val(preferredDoctor);
                
                // Check doctor availability when modal is shown
                if (doctorId && appointmentId) {
                    checkDoctorAvailability(appointmentId, doctorId);
                } else {
                    // If no requested doctor, disable the confirm button and show warning
                    $('#doctorAvailabilityWarning').text('No doctor requested for this appointment.');
                    $('#doctorAvailabilityWarning').show();
                    $('#confirmAssignButton').prop('disabled', true);
                }
                
                $('#assignDoctorModal').modal('show');
            });

            function viewAppointment(appointmentId) {
                // Load appointment details via AJAX
                $.ajax({
                    url: '<%= request.getContextPath()%>/AppointmentServlet',
                    method: 'GET',
                    data: {
                        action: 'viewDetails',
                        id: appointmentId
                    },
                    success: function(data) {
                        if (data.appointment) {
                            const apt = data.appointment;
                            
                            // Populate modal with data
                            $('#view-appointment-id').text(apt.id);
                            $('#view-appointment-status').text(apt.status.toUpperCase()).removeClass().addClass('status-badge status-' + apt.status.toLowerCase().replace(' ', '-'));
                            $('#view-appointment-date').text(apt.date || 'Not set');
                            $('#view-appointment-time').text(apt.time || 'Not set');
                            
                            // Customer info
                            if (apt.customer) {
                                $('#view-customer-name').text(apt.customer.name || 'Not provided');
                                $('#view-customer-email').text(apt.customer.email || 'Not provided');
                                $('#view-customer-phone').text(apt.customer.phone || 'Not provided');
                                $('#view-customer-gender').text(apt.customer.gender || 'Not specified');
                            } else {
                                $('#view-customer-name, #view-customer-email, #view-customer-phone, #view-customer-gender').text('Not available');
                            }
                            
                            // Treatment and doctor info
                            $('#view-treatment-name').text(apt.treatment ? apt.treatment.name : 'Not assigned');
                            $('#view-doctor-name').text(apt.doctor ? 'Dr. ' + apt.doctor.name : 'Not assigned');
                            $('#view-doctor-spec').text(apt.doctor ? apt.doctor.specialization : 'N/A');
                            
                            // Staff info
                            $('#view-staff-name').text(apt.staff ? apt.staff.name : 'Not assigned');
                            
                            // Messages
                            $('#view-customer-message').text(apt.customerMessage || 'No message provided');
                            $('#view-doctor-message').text(apt.doctorMessage || 'No message from doctor');
                            $('#view-staff-message').text(apt.staffMessage || 'No staff notes');
                            
                            // Show modal
                            $('#viewDetailsModal').modal('show');
                        } else {
                            alert('Failed to load appointment details.');
                        }
                    },
                    error: function() {
                        alert('Error loading appointment details. Please try again.');
                    }
                });
            }

            // Function to check doctor availability
            function checkDoctorAvailability(appointmentId, doctorId, date, time) {
                $.ajax({
                    url: '<%= request.getContextPath() %>/AppointmentServlet',
                    method: 'GET',
                    data: {
                        action: 'checkDoctorAvailability',
                        appointmentId: appointmentId,
                        doctorId: doctorId,
                        appointmentDate: date,
                        appointmentTime: time
                    },
                    success: function(response) {
                        if (response.available) {
                            $('#doctorAvailabilityWarning').hide();
                            $('#confirmAssignButton').prop('disabled', false);
                        } else {
                            $('#doctorAvailabilityWarning').show();
                            $('#confirmAssignButton').prop('disabled', true);
                        }
                    },
                    error: function() {
                        alert('Error checking doctor availability. Please try again.');
                    }
                });
            }

    // Function to handle Reject & Reschedule
    function rejectAndReschedule() {
        const appointmentId = $('#assignDoctorAppointmentId').val();
        $('#requireRescheduleAppointmentId').val(appointmentId);
        $('#assignDoctorModal').modal('hide');
        $('#requireRescheduleModal').modal('show');
    }            // Auto-dismiss alerts
            $(document).ready(function () {
                setTimeout(function () {
                    $('.alert').fadeOut();
                }, 5000);

                // Initialize tooltips
                $('[data-toggle="tooltip"]').tooltip();
            });

            // Form validation
            $('#requireRescheduleForm').on('submit', function(e) {
                if ($('#rescheduleReason').val().trim() === '') {
                    e.preventDefault();
                    alert('Please provide a reason for the reschedule request.');
                    return false;
                }
            });

            $('#cancelAppointmentForm').on('submit', function(e) {
                if ($('#cancellationReason').val().trim() === '') {
                    e.preventDefault();
                    alert('Please provide a reason for cancellation.');
                    return false;
                }
                if (!confirm('Are you sure you want to cancel this appointment? This action cannot be undone.')) {
                    e.preventDefault();
                    return false;
                }
            });

            $('#assignDoctorForm').on('submit', function(e) {
                if ($('#assignDoctorDoctorId').val() === '') {
                    e.preventDefault();
                    alert('No doctor assigned to this appointment.');
                    return false;
                }
                if ($('#confirmAssignButton').prop('disabled')) {
                    e.preventDefault();
                    alert('Cannot assign doctor - doctor is unavailable for this appointment.');
                    return false;
                }
            });
        </script>
    </body>
</html>
