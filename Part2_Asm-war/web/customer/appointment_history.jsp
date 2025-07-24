<%--<%@page contentType="text/html" pageEncoding="UTF-8"%>--%>
<%@ page import="java.util.List" %>
<%@ page import="java.text.DecimalFormat" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="model.Doctor" %>
<%@ page import="model.Treatment" %>
<%@ page import="model.Customer" %>
<%@ page import="model.Appointment" %>
<%@ page import="model.Payment" %>
<%@ page import="model.CounterStaff" %>

<%
    // Get data from servlet
    List<Appointment> appointmentList = (List<Appointment>) request.getAttribute("appointmentList");
    List<Doctor> doctorList = (List<Doctor>) request.getAttribute("doctorList");
    List<Treatment> treatmentList = (List<Treatment>) request.getAttribute("treatmentList");
    List<Payment> paymentList = (List<Payment>) request.getAttribute("paymentList");
    List<CounterStaff> staffList = (List<CounterStaff>) request.getAttribute("staffList");

    // Get selected status filter
    String selectedStatus = request.getParameter("status");
    if (selectedStatus == null) {
        selectedStatus = "all";
    }
%>

<%
    // Check if user is logged in
    Customer loggedInCustomer = (Customer) session.getAttribute("customer");

    if (loggedInCustomer == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
%>

<!DOCTYPE html>
<html lang="en">

    <head>
        <title>Appointment History - APU Medical Center</title>
        <%@ include file="/includes/head.jsp" %>
    </head>

    <body id="top" data-spy="scroll" data-target=".navbar-collapse" data-offset="50">

        <%@ include file="/includes/preloader.jsp" %>
        <%@ include file="/includes/header.jsp" %>
        <%@ include file="/includes/navbar.jsp" %>

        <!-- APPOINTMENT HISTORY -->
        <section class="appointment-history" style="padding: 100px 0;">
            <div class="container">
                
                <div class="col-md-12 col-sm-12">
                    <div class="section-title wow fadeInUp" data-wow-delay="0.1s">
                        <h2>My Appointment History</h2>
                        <p>View and manage your medical appointments</p>
                    </div>
                </div>

                <!-- Filter Section -->
                <div class="row">
                    <div class="col-md-8 col-md-offset-2">
                        <div class="filter-section">
                            <h4><i class="fa fa-filter"></i> Filter by Status</h4>
                            <div class="form-group">
                                <label for="statusFilter">Select Appointment Status:</label>
                                <select id="statusFilter" name="status" class="form-control" onchange="filterAppointments()">
                                    <option value="all" <%= "all".equals(selectedStatus) ? "selected" : ""%>>All Appointments</option>
                                    <option value="pending" <%= "pending".equals(selectedStatus) ? "selected" : ""%>>Pending</option>
                                    <option value="approved" <%= "approved".equals(selectedStatus) ? "selected" : ""%>>Approved</option>
                                    <option value="completed" <%= "completed".equals(selectedStatus) ? "selected" : ""%>>Completed</option>
                                    <option value="cancelled" <%= "cancelled".equals(selectedStatus) ? "selected" : ""%>>Cancelled</option>
                                </select>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Appointment History List -->
                <div class="row">
                    <div class="col-md-10 col-md-offset-1">
                        <%
                            if (appointmentList != null && !appointmentList.isEmpty()) {
                                DecimalFormat df = new DecimalFormat("0.00");
                                SimpleDateFormat dateFormat = new SimpleDateFormat("dd MMM yyyy");
                                SimpleDateFormat timeFormat = new SimpleDateFormat("HH:mm");

                                boolean hasMatchingAppointments = false;

                                for (int i = 0; i < appointmentList.size(); i++) {
                                    Appointment appointment = appointmentList.get(i);

                                    // Filter appointments by status
                                    if (selectedStatus != null
                                            && ("pending".equals(selectedStatus)
                                            || "ongoing".equals(selectedStatus)
                                            || "completed".equals(selectedStatus)
                                            || "cancelled".equals(selectedStatus))
                                            && !selectedStatus.equals(appointment.getStatus())) {
                                        continue;
                                    }

                                    hasMatchingAppointments = true;

                                    // Find related doctor
                                    Doctor appointmentDoctor = null;
                                    if (doctorList != null) {
                                        for (Doctor doc : doctorList) {
                                            if (doc.getId() == appointment.getId()) {
                                                appointmentDoctor = doc;
                                                break;
                                            }
                                        }
                                    }

                                    // Find related treatment
                                    Treatment appointmentTreatment = null;
                                    if (treatmentList != null) {
                                        for (Treatment treatment : treatmentList) {
                                            if (treatment.getId() == appointment.getId()) {
                                                appointmentTreatment = treatment;
                                                break;
                                            }
                                        }
                                    }

                                    // Find related payment
                                    Payment appointmentPayment = null;
                                    if (paymentList != null) {
                                        for (Payment payment : paymentList) {
                                            if (payment.getId() == appointment.getId()) {
                                                appointmentPayment = payment;
                                                break;
                                            }
                                        }
                                    }

                                    // Find counter staff
                                    CounterStaff counterStaff = null;
                                    if (staffList != null && appointment.getId() > 0) {
                                        for (CounterStaff staff : staffList) {
                                            if (staff.getId() == appointment.getId()) {
                                                counterStaff = staff;
                                                break;
                                            }
                                        }
                                    }
                        %>

                        <!-- Appointment Container -->
                        <div class="history-container">
                            <!-- Header -->
                            <div class="history-header">
                                <div>
                                    <h4 style="margin: 0;">Appointment #<%= appointment.getId()%></h4>
                                    <small>Booked for <%= loggedInCustomer.getName()%></small>
                                </div>
                                <div>
                                    <span class="status-badge status-<%= appointment.getStatus()%>">
                                        <%= appointment.getStatus().toUpperCase()%>
                                    </span>
                                </div>
                            </div>

                            <!-- Content -->
                            <div class="history-content">
                                <!-- Appointment Details Section -->
                                <div class="history-section">
                                    <div class="section-title">
                                        <i class="fa fa-calendar-check-o"></i> Appointment Details
                                    </div>

                                    <div class="info-row">
                                        <div class="info-label">Doctor:</div>
                                        <div class="info-value">
                                            <%= appointmentDoctor != null ? appointmentDoctor.getName() : "Not assigned"%>
                                            <% if (appointmentDoctor != null && appointmentDoctor.getSpecialization() != null) {%>
                                            - <em><%= appointmentDoctor.getSpecialization()%></em>
                                            <% }%>
                                        </div>
                                    </div>

                                    <div class="info-row">
                                        <div class="info-label">Treatment:</div>
                                        <div class="info-value">
                                            <%= appointmentTreatment != null ? appointmentTreatment.getName() : "Not specified"%>
                                        </div>
                                    </div>

                                    <div class="info-row">
                                        <div class="info-label">Counter Staff:</div>
                                        <div class="info-value">
                                            <%= counterStaff != null ? counterStaff.getName() : "Not assigned"%>
                                        </div>
                                    </div>

                                    <div class="info-row">
                                        <div class="info-label">Date:</div>
                                        <div class="info-value">
                                            <%= appointment.getAppointmentDate() != null ? appointment.getAppointmentDate() : "Not scheduled"%>
                                        </div>
                                    </div>

                                    <div class="info-row">
                                        <div class="info-label">Time:</div>
                                        <div class="info-value">
                                            <%= appointment.getAppointmentTime() != null ? appointment.getAppointmentTime() : "Not scheduled"%>
                                        </div>
                                    </div>

                                    <div class="info-row">
                                        <div class="info-label">Your Message:</div>
                                        <div class="info-value">
                                            <% if (appointment.getCustMessage() != null && !appointment.getCustMessage().trim().isEmpty()) {%>
                                            "<%= appointment.getCustMessage()%>"
                                            <% } else { %>
                                            <span style="color: #999; font-style: italic;">No message provided</span>
                                            <% } %>
                                        </div>
                                    </div>

                                    <div class="info-row">
                                        <div class="info-label">Doctor's Notes:</div>
                                        <div class="info-value">
                                            <% if ("completed".equals(appointment.getStatus())
                                                        && appointment.getDocMessage() != null
                                                        && !appointment.getDocMessage().trim().isEmpty()) {%>
                                            <span style="color: #28a745; font-style: italic;">
                                                "<%= appointment.getDocMessage()%>"
                                            </span>
                                            <% } else if ("completed".equals(appointment.getStatus())) { %>
                                            <span style="color: #999; font-style: italic;">No notes provided by doctor</span>
                                            <% } else { %>
                                            <span style="color: #999; font-style: italic;">Available after consultation</span>
                                            <% } %>
                                        </div>
                                    </div>
                                </div>

                                <!-- Payment Details Section -->
                                <div class="history-section">
                                    <div class="section-title">
                                        <i class="fa fa-credit-card"></i> Payment Details
                                    </div>

                                    <% if (appointmentPayment != null) {%>
                                    <div class="info-row">
                                        <div class="info-label">Payment Status:</div>
                                        <div class="info-value">
                                            <span class="status-badge payment-<%= appointmentPayment.getStatus()%>">
                                                <%= appointmentPayment.getStatus().toUpperCase()%>
                                            </span>
                                        </div>
                                    </div>

                                    <div class="info-row">
                                        <div class="info-label">Amount:</div>
                                        <div class="info-value">
                                            RM <%= df.format(appointmentPayment.getAmount())%>
                                        </div>
                                    </div>

                                    <div class="info-row">
                                        <div class="info-label">Payment Method:</div>
                                        <div class="info-value">
                                            <%= appointmentPayment.getPaymentMethod() != null
                                                    ? appointmentPayment.getPaymentMethod().substring(0, 1).toUpperCase()
                                                    + appointmentPayment.getPaymentMethod().substring(1) : "Not specified"%>
                                        </div>
                                    </div>

                                    <% if ("paid".equals(appointmentPayment.getStatus())
                                                && appointmentPayment.getPaymentDate() != null) {%>
                                    <div class="info-row">
                                        <div class="info-label">Payment Date:</div>
                                        <div class="info-value">
                                            <%= appointmentPayment.getPaymentDate()%>
                                        </div>
                                    </div>
                                    <% } %>
                                    <% } else { %>
                                    <div class="info-row">
                                        <div class="info-label">Payment Status:</div>
                                        <div class="info-value">
                                            <span class="status-badge payment-pending">NO PAYMENT RECORD</span>
                                        </div>
                                    </div>
                                    <div class="info-row">
                                        <div class="info-label">Note:</div>
                                        <div class="info-value" style="color: #666; font-style: italic;">
                                            Payment information will be available once processed
                                        </div>
                                    </div>
                                    <% } %>
                                </div>

                                <!-- Action Buttons -->
                                <div class="action-buttons">
                                    <% if ("completed".equals(appointment.getStatus())) {%>
                                    <button type="button" class="btn-action btn-feedback" 
                                            onclick="submitFeedback(<%= appointment.getId()%>)">
                                        <i class="fa fa-star"></i> Submit Feedback
                                    </button>
                                    <% } %>

                                    <% if (appointmentPayment != null && "paid".equals(appointmentPayment.getStatus())) {%>
                                    <button type="button" class="btn-action btn-receipt" 
                                            onclick="generateReceipt(<%= appointment.getId()%>)">
                                        <i class="fa fa-file-pdf-o"></i> Download Receipt
                                    </button>
                                    <% } else { %>
                                    <button type="button" class="btn-action btn-receipt" disabled 
                                            style="background: #ccc; cursor: not-allowed;">
                                        <i class="fa fa-file-pdf-o"></i> Receipt Not Available
                                    </button>
                                    <% } %>
                                </div>
                            </div>
                        </div>
                        <% } %>
                        <%
                            // Show message if no appointments match the filter
                            if (!hasMatchingAppointments) {
                        %>
                        <div class="no-appointments">
                            <i class="fa fa-calendar-times-o" style="font-size: 64px; color: #ccc; margin-bottom: 20px;"></i>
                            <h3>No appointments found</h3>
                            <% if (!"all".equals(selectedStatus)) {%>
                            <p>No appointments with status "<%= selectedStatus%>" were found.</p>
                            <p>Try selecting a different status or view all appointments.</p>
                            <% } else { %>
                            <p>You haven't booked any appointments yet.</p>
                            <a href="appointment.jsp" class="btn btn-primary">Book Your First Appointment</a>
                            <% } %>
                        </div>
                        <%
                            }
                        } else {
                        %>
                        <div class="no-appointments">
                            <i class="fa fa-calendar-times-o" style="font-size: 64px; color: #ccc; margin-bottom: 20px;"></i>
                            <h3>No appointment history</h3>
                            <p>You haven't booked any appointments yet.</p>
                            <a href="appointment.jsp" class="btn btn-primary">Book Your First Appointment</a>
                        </div>
                        <% }%>
                    </div>
                </div>
            </div>
        </section>

        <%@ include file="/includes/footer.jsp" %>
        <%@ include file="/includes/scripts.jsp" %>


    </body>

</html>
