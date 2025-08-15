<%@page import="model.Appointment"%>
<%@page import="model.CounterStaff"%>
<%@page import="model.Customer"%>
<%@page import="model.Doctor"%>
<%@page import="model.Treatment"%>
<%@page import="model.Manager"%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="java.util.Date" %>

<%
    // Check if manager is logged in
    Manager loggedInManager = (Manager) session.getAttribute("manager");

    if (loggedInManager == null) {
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

    // Get info message
    String infoMessage = (String) request.getAttribute("infoMessage");

    SimpleDateFormat dateFormat = new SimpleDateFormat("dd MMM yyyy");
    SimpleDateFormat timeFormat = new SimpleDateFormat("HH:mm");
%>

<!DOCTYPE html>
<html lang="en">
    <head>
        <title>View Appointments - APU Medical Center</title>
        <%@ include file="/includes/head.jsp" %>
        <link rel="stylesheet" href="<%= request.getContextPath()%>/css/manager-homepage.css">
        <link rel="stylesheet" href="<%= request.getContextPath()%>/css/manage-staff.css">
        <style>
            .appointment-row:hover {
                background-color: #f1f5ff;
                cursor: pointer;
            }
            
            .status-badge {
                padding: 4px 12px;
                border-radius: 20px;
                font-size: 0.85em;
                font-weight: bold;
                text-transform: uppercase;
                display: inline-block; /* Ensure it displays as a block */
                min-width: 80px; /* Minimum width */
                text-align: center; /* Center the text */
            }
            .status-pending { background: #fff3cd; color: #856404; }
            .status-approved { background: #d4edda; color: #155724; }
            .status-completed { background: #cce5ff; color: #004085; }
            .status-cancelled { background: #f8d7da; color: #721c24; }
            .status-overdue { background: #f5c6cb; color: #721c24; }
            .status-reschedule { background: #ffeaa7; color: #6c5502; }
            
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
            
            .table th {
                cursor: pointer;
            }
            
            .modal-header.bg-primary {
                color: white;
            }
            
            #viewDetailsModal .modal-body {
                padding: 20px;
            }
            
            .detail-section {
                margin-bottom: 20px;
                border-bottom: 1px solid #eee;
                padding-bottom: 15px;
            }
            
            .detail-section:last-child {
                border-bottom: none;
            }
            
            .detail-item {
                margin-bottom: 10px;
            }
            
            .detail-label {
                font-weight: bold;
                color: #667eea;
            }
            
            .detail-value {
                font-size: 0.95em;
            }
            
            .modal-dialog.modal-lg {
                max-width: 80%;
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
                            <span style="color:white">View Appointments</span>
                        </h1>
                        <p class="lead wow fadeInUp" data-wow-delay="0.2s" style="color: whitesmoke">
                            Search, filter, and view appointment details
                        </p>
                        <nav aria-label="breadcrumb" class="wow fadeInUp" data-wow-delay="0.3s">
                            <ol class="breadcrumb" style="background: transparent; margin: 0;">
                                <li class="breadcrumb-item">
                                    <a href="<%= request.getContextPath()%>/ManagerHomepageServlet" style="color: rgba(255,255,255,0.8);">Dashboard</a>
                                </li>
                                <li class="breadcrumb-item active" style="color: white;">View Appointments</li>
                            </ol>
                        </nav>
                    </div>
                </div>
            </div>
        </section>

        <!-- MAIN CONTENT -->
        <section style="padding: 40px 0; background: #f5f5f5;">
            <div class="container">
                <!-- Info Message for No Results -->
                <% if (infoMessage != null) { %>
                <div class="alert alert-info alert-dismissible wow fadeInUp">
                    <button type="button" class="close" data-dismiss="alert">&times;</button>
                    <i class="fa fa-info-circle"></i>
                    <%= infoMessage %>
                </div>
                <% } %>

                <!-- SEARCH AND FILTER SECTION -->
                <div class="search-filters wow fadeInUp" data-wow-delay="0.2s">
                    <h3><i class="fa fa-search"></i> Search & Filter Appointments</h3>

                    <form method="GET" action="<%= request.getContextPath()%>/ManagerServlet" class="search-form">
                        <input type="hidden" name="action" value="viewAppointments">

                        <div class="filter-row">
                            <div class="form-group">
                                <label for="search">Search by Customer or ID</label>
                                <input type="text" class="form-control" id="search" name="search" 
                                       value="<%= searchQuery%>" placeholder="Enter customer name or ID...">
                            </div>

                            <div class="form-group">
                                <label for="status">Status</label>
                                <select class="form-control" id="status" name="status">
                                    <option value="all" <%= "all".equals(statusFilter) ? "selected" : ""%>>All Statuses</option>
                                    <option value="pending" <%= "pending".equals(statusFilter) ? "selected" : ""%>>Pending</option>
                                    <option value="approved" <%= "approved".equals(statusFilter) ? "selected" : ""%>>Approved</option>
                                    <option value="completed" <%= "completed".equals(statusFilter) ? "selected" : ""%>>Completed</option>
                                    <option value="cancelled" <%= "cancelled".equals(statusFilter) ? "selected" : ""%>>Cancelled</option>
                                    <option value="reschedule required" <%= "reschedule required".equals(statusFilter) ? "selected" : ""%>>Reschedule Required</option>
                                </select>
                            </div>

                            <div class="form-group">
                                <label for="doctor">Doctor</label>
                                <select class="form-control" id="doctor" name="doctor">
                                    <option value="all" <%= "all".equals(doctorFilter) ? "selected" : ""%>>All Doctors</option>
                                    <% if (doctorList != null) { 
                                        for (Doctor doctor : doctorList) { %>
                                    <option value="<%= doctor.getId() %>" <%= String.valueOf(doctor.getId()).equals(doctorFilter) ? "selected" : ""%>>
                                        Dr. <%= doctor.getName() %>
                                    </option>
                                    <% } 
                                    } %>
                                </select>
                            </div>
                        </div>

                        <div class="filter-row">
                            <div class="form-group">
                                <label for="treatment">Treatment</label>
                                <select class="form-control" id="treatment" name="treatment">
                                    <option value="all" <%= "all".equals(treatmentFilter) ? "selected" : ""%>>All Treatments</option>
                                    <% if (treatmentList != null) { 
                                        for (Treatment treatment : treatmentList) { %>
                                    <option value="<%= treatment.getId() %>" <%= String.valueOf(treatment.getId()).equals(treatmentFilter) ? "selected" : ""%>>
                                        <%= treatment.getName() %>
                                    </option>
                                    <% } 
                                    } %>
                                </select>
                            </div>

                            <div class="form-group">
                                <label for="staff">Counter Staff</label>
                                <select class="form-control" id="staff" name="staff">
                                    <option value="all" <%= "all".equals(staffFilter) ? "selected" : ""%>>All Staff</option>
                                    <% if (staffList != null) { 
                                        for (CounterStaff staff : staffList) { %>
                                    <option value="<%= staff.getId() %>" <%= String.valueOf(staff.getId()).equals(staffFilter) ? "selected" : ""%>>
                                        <%= staff.getName() %>
                                    </option>
                                    <% } 
                                    } %>
                                </select>
                            </div>

                            <div class="form-group">
                                <label for="date">Date</label>
                                <input type="date" class="form-control" id="date" name="date" value="<%= dateFilter %>">
                            </div>
                        </div>

                        <div class="text-center">
                            <button type="submit" class="btn btn-primary">
                                <i class="fa fa-search"></i> Search
                            </button>
                            <a href="<%= request.getContextPath()%>/ManagerServlet?action=viewAppointments" class="btn btn-secondary">
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

                    <!-- Appointments Table -->
                    <div class="staff-table">
                        <% if (appointmentList != null && !appointmentList.isEmpty()) { %>
                        <table class="table table-hover" id="appointmentsTable">
                            <thead>
                                <tr>
                                    <th class="sortable" onclick="sortTable('appointmentsTable', 0, 'number')">
                                        ID <i class="fa fa-sort"></i>
                                    </th>
                                    <th class="sortable" onclick="sortTable('appointmentsTable', 1, 'string')">
                                        Customer <i class="fa fa-sort"></i>
                                    </th>
                                    <th class="sortable" onclick="sortTable('appointmentsTable', 2, 'string')">
                                        Doctor <i class="fa fa-sort"></i>
                                    </th>
                                    <th class="sortable" onclick="sortTable('appointmentsTable', 3, 'string')">
                                        Treatment <i class="fa fa-sort"></i>
                                    </th>
                                    <th class="sortable" onclick="sortTable('appointmentsTable', 4, 'date')">
                                        Date <i class="fa fa-sort"></i>
                                    </th>
                                    <th class="sortable" onclick="sortTable('appointmentsTable', 5, 'string')">
                                        Time <i class="fa fa-sort"></i>
                                    </th>
                                    <th class="sortable" onclick="sortTable('appointmentsTable', 6, 'string')">
                                        Status <i class="fa fa-sort"></i>
                                    </th>
                                    <th>Actions</th>
                                </tr>
                            </thead>
                            <tbody>
                                <% for (Appointment appointment : appointmentList) { 
                                    String statusClass = "";
                                    if ("pending".equalsIgnoreCase(appointment.getStatus())) {
                                        statusClass = "status-pending";
                                    } else if ("approved".equalsIgnoreCase(appointment.getStatus())) {
                                        statusClass = "status-approved";
                                    } else if ("completed".equalsIgnoreCase(appointment.getStatus())) {
                                        statusClass = "status-completed";
                                    } else if ("cancelled".equalsIgnoreCase(appointment.getStatus())) {
                                        statusClass = "status-cancelled";
                                    } else if ("overdue".equalsIgnoreCase(appointment.getStatus())) {
                                        statusClass = "status-overdue";
                                    } else if (appointment.getStatus().toLowerCase().contains("reschedule")) {
                                        statusClass = "status-reschedule";
                                    }
                                    
                                    // Debug: Print the appointment ID
                                    String appointmentId = String.valueOf(appointment.getId());
                                    System.out.println("Appointment ID: " + appointmentId);
                                %>
                                <tr class="appointment-row" 
                                   id="appointment-<%=appointmentId%>"
                                   data-id="<%=appointmentId%>"
                                   data-status="<%=appointment.getStatus()%>"
                                   data-customer-name="<%=appointment.getCustomer().getName()%>"
                                   data-customer-email="<%=appointment.getCustomer().getEmail()%>"
                                   data-customer-phone="<%=appointment.getCustomer().getPhone()%>"
                                   data-doctor-name="<%= appointment.getDoctor() != null ? "Dr. " + appointment.getDoctor().getName() : "Not Assigned" %>"
                                   data-doctor-specialization="<%= appointment.getDoctor() != null ? appointment.getDoctor().getSpecialization() : "" %>"
                                   data-treatment-name="<%=appointment.getTreatment().getName()%>"
                                   data-treatment-duration="30 minutes"
                                   data-treatment-price="$<%= appointment.getTreatment().getBaseConsultationCharge() %>"
                                   data-date="<%=dateFormat.format(appointment.getAppointmentDate())%>"
                                   data-time="<%=timeFormat.format(appointment.getAppointmentTime())%>"
                                   data-customer-message="<%= appointment.getCustMessage() != null ? appointment.getCustMessage() : "" %>"
                                   data-doctor-message="<%= appointment.getDocMessage() != null ? appointment.getDocMessage() : "" %>"
                                   data-staff-message="<%= appointment.getStaffMessage() != null ? appointment.getStaffMessage() : "" %>"
                                   onclick="viewAppointment('<%=appointmentId%>')">
                                    <td><%=appointmentId%></td>
                                    <td>
                                        <%=appointment.getCustomer().getName()%>
                                    </td>
                                    <td>
                                        <% if (appointment.getDoctor() != null) { %>
                                            Dr. <%=appointment.getDoctor().getName()%>
                                        <% } else { %>
                                            <span class="text-muted">Not Assigned</span>
                                        <% } %>
                                    </td>
                                    <td><%=appointment.getTreatment().getName()%></td>
                                    <td><%=dateFormat.format(appointment.getAppointmentDate())%></td>
                                    <td><%=timeFormat.format(appointment.getAppointmentTime())%></td>
                                    <td>
                                        <span class="status-badge <%=statusClass%>">
                                            <%=appointment.getStatus()%>
                                        </span>
                                    </td>
                                    <td>
                                        <button class="btn btn-sm btn-view" onclick="event.stopPropagation(); viewAppointment('<%=appointmentId%>');">
                                            <i class="fa fa-eye"></i> View
                                        </button>
                                    </td>
                                </tr>
                                <% } %>
                            </tbody>
                        </table>
                        <% } else { %>
                        <div class="no-data">
                            <i class="fa fa-calendar-times-o"></i>
                            <h4>No Appointments Found</h4>
                            <p>No appointments match your search criteria.</p>
                        </div>
                        <% } %>
                    </div>
                </div>
            </div>
        </section>

        <!-- View Appointment Details Modal -->
        <div class="modal fade" id="viewDetailsModal" tabindex="-1" role="dialog">
            <div class="modal-dialog modal-lg" role="document">
                <div class="modal-content">
                    <div class="modal-header bg-primary">
                        <h4 class="modal-title" style="color: #ffffff;">
                            <i class="fa fa-calendar-check-o"></i> Appointment Details
                        </h4>
                        <button type="button" class="close" data-dismiss="modal" aria-label="Close" style="color: white;">
                            <span aria-hidden="true">&times;</span>
                        </button>
                    </div>
                    <div class="modal-body">
                        <div class="row">
                            <div class="col-md-6">
                                <div class="detail-section">
                                    <h5><i class="fa fa-info-circle"></i> Basic Information</h5>
                                    <div class="detail-item">
                                        <div class="detail-label">Appointment ID:</div>
                                        <div class="detail-value" id="view-id"></div>
                                    </div>
                                    <div class="detail-item">
                                        <div class="detail-label">Status:</div>
                                        <div class="detail-value" id="view-status-text"></div>
                                    </div>
                                    <div class="detail-item">
                                        <div class="detail-label">Date:</div>
                                        <div class="detail-value" id="view-date"></div>
                                    </div>
                                    <div class="detail-item">
                                        <div class="detail-label">Time:</div>
                                        <div class="detail-value" id="view-time"></div>
                                    </div>
                                </div>
                            </div>
                            <div class="col-md-6">
                                <div class="detail-section">
                                    <h5><i class="fa fa-user"></i> Customer Information</h5>
                                    <div class="detail-item">
                                        <div class="detail-label">Name:</div>
                                        <div class="detail-value" id="view-customer-name"></div>
                                    </div>
                                    <div class="detail-item">
                                        <div class="detail-label">Email:</div>
                                        <div class="detail-value" id="view-customer-email"></div>
                                    </div>
                                    <div class="detail-item">
                                        <div class="detail-label">Phone:</div>
                                        <div class="detail-value" id="view-customer-phone"></div>
                                    </div>
                                </div>
                            </div>
                        </div>
                        
                        <div class="row">
                            <div class="col-md-6">
                                <div class="detail-section">
                                    <h5><i class="fa fa-user-md"></i> Doctor Information</h5>
                                    <div class="detail-item">
                                        <div class="detail-label">Doctor:</div>
                                        <div class="detail-value" id="view-doctor-name"></div>
                                    </div>
                                    <div class="detail-item">
                                        <div class="detail-label">Specialization:</div>
                                        <div class="detail-value" id="view-doctor-specialization"></div>
                                    </div>
                                </div>
                            </div>
                            <div class="col-md-6">
                                <div class="detail-section">
                                    <h5><i class="fa fa-medkit"></i> Treatment Information</h5>
                                    <div class="detail-item">
                                        <div class="detail-label">Treatment Type:</div>
                                        <div class="detail-value" id="view-treatment-type"></div>
                                    </div>
                                    <div class="detail-item">
                                        <div class="detail-label">Duration:</div>
                                        <div class="detail-value" id="view-treatment-duration"></div>
                                    </div>
                                    <div class="detail-item">
                                        <div class="detail-label">Price:</div>
                                        <div class="detail-value" id="view-treatment-price"></div>
                                    </div>
                                </div>
                            </div>
                        </div>
                        
                        <!-- Messages Section -->
                        <div class="detail-section">
                            <h5><i class="fa fa-comments"></i> Messages</h5>
                            <div class="detail-item">
                                <div class="detail-label">Customer Message:</div>
                                <div class="detail-value" id="view-customer-message"></div>
                            </div>
                            <div class="detail-item">
                                <div class="detail-label">Doctor Message:</div>
                                <div class="detail-value" id="view-doctor-message"></div>
                            </div>
                            <div class="detail-item">
                                <div class="detail-label">Staff Notes:</div>
                                <div class="detail-value" id="view-staff-message"></div>
                            </div>
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
            // View appointment details
            function viewAppointment(appointmentId) {
                console.log("=========== View Appointment Started ===========");
                console.log("Looking for appointment with ID:", appointmentId);
                
                // Check DOM readiness - are all elements ready?
                console.log("DOM ready state:", document.readyState);
                console.log("Modal container exists:", !!document.getElementById('viewDetailsModal'));
                console.log("Status badge element exists:", !!document.getElementById('view-status-badge'));
                console.log("Date time element exists:", !!document.getElementById('view-datetime'));
                
                // Check if modal elements exist
                console.log("Modal elements check:");
                console.log("view-id element:", document.getElementById('view-id'));
                console.log("view-status-badge element:", document.getElementById('view-status-badge'));
                console.log("view-status-container element:", document.getElementById('view-status-container'));
                
                // Check if appointmentId is valid
                if (!appointmentId || appointmentId === 'null' || appointmentId === 'undefined') {
                    console.error("Invalid appointment ID:", appointmentId);
                    alert('Error: Invalid appointment ID');
                    return;
                }
                
                // Find the row directly by its ID
                let row = document.getElementById('appointment-' + appointmentId);
                console.log("Found row by ID:", row);
                
                if (!row) {
                    // Try using data-id
                    row = document.querySelector('tr[data-id="' + appointmentId + '"]');
                    console.log("Found row by data-id:", row);
                }
                
                if (!row) {
                    // Try all rows
                    const allRows = document.querySelectorAll('tr.appointment-row');
                    console.log("Trying all rows. Total:", allRows.length);
                    
                    for (const r of allRows) {
                        console.log("Checking row:", r.getAttribute('data-id'), "vs", appointmentId);
                        if (r.getAttribute('data-id') == appointmentId) {
                            row = r;
                            console.log("Found match by iteration!");
                            break;
                        }
                    }
                }
                
                if (!row) {
                    console.error("No row found for appointment ID:", appointmentId);
                    alert('Error: Appointment not found in the table.');
                    return;
                }
                
                console.log("Found row:", row);
                
                // Get data from the table
                const id = row.getAttribute('data-id');
                const status = row.getAttribute('data-status');
                const customerName = row.getAttribute('data-customer-name');
                const customerEmail = row.getAttribute('data-customer-email');
                const customerPhone = row.getAttribute('data-customer-phone');
                const doctorName = row.getAttribute('data-doctor-name');
                const doctorSpecialization = row.getAttribute('data-doctor-specialization');
                const treatmentName = row.getAttribute('data-treatment-name');
                const treatmentDuration = row.getAttribute('data-treatment-duration');
                const treatmentPrice = row.getAttribute('data-treatment-price');
                const appointmentDate = row.getAttribute('data-date');
                const appointmentTime = row.getAttribute('data-time');
                const customerMessage = row.getAttribute('data-customer-message');
                const doctorMessage = row.getAttribute('data-doctor-message');
                const staffMessage = row.getAttribute('data-staff-message');
                
                // Set appointment details in modal
                $('#view-id').text(id);
                
                // Set status as plain text
                console.log("Setting status text. Status:", status);
                const statusElement = document.getElementById('view-status-text');
                if (statusElement) {
                    statusElement.textContent = status || 'Not available';
                    console.log("Status text set to:", status);
                } else {
                    console.error("Status element not found");
                }
                
                // Set date and time separately
                console.log("Date and time values:", { appointmentDate, appointmentTime });
                
                // Set date
                const dateElement = document.getElementById('view-date');
                if (dateElement) {
                    dateElement.textContent = appointmentDate || 'Not scheduled';
                    console.log("Date set to:", appointmentDate);
                } else {
                    console.error("Date element not found");
                }
                
                // Set time
                const timeElement = document.getElementById('view-time');
                if (timeElement) {
                    timeElement.textContent = appointmentTime || 'Not specified';
                    console.log("Time set to:", appointmentTime);
                } else {
                    console.error("Time element not found");
                }
                
                // Customer details
                $('#view-customer-name').text(customerName || 'Not available');
                $('#view-customer-email').text(customerEmail || 'Not available');
                $('#view-customer-phone').text(customerPhone || 'Not provided');
                
                // Doctor details
                if (doctorName) {
                    $('#view-doctor-name').text(doctorName);
                    $('#view-doctor-specialization').text(doctorSpecialization || 'General');
                } else {
                    $('#view-doctor-name').text('Not assigned');
                    $('#view-doctor-specialization').text('N/A');
                }
                
                // Treatment details
                $('#view-treatment-type').text(treatmentName);
                $('#view-treatment-duration').text(treatmentDuration);
                $('#view-treatment-price').text(treatmentPrice);
                
                // Messages
                $('#view-customer-message').text(customerMessage || 'No message provided');
                $('#view-doctor-message').text(doctorMessage || 'No message from doctor');
                $('#view-staff-message').text(staffMessage || 'No staff notes');
                
                // Show modal
                $('#viewDetailsModal').modal('show');
                
                // Final verification after all updates
                console.log("Final verification after all updates:");
                console.log("Status text final state:", document.getElementById('view-status-text')?.outerHTML || "Not found");
                console.log("Date final state:", document.getElementById('view-date')?.outerHTML || "Not found");
                console.log("Time final state:", document.getElementById('view-time')?.outerHTML || "Not found");
                console.log("=========== View Appointment Completed ===========");
            }

            // Table Sorting Function
            let sortDirections = {}; // Track sort direction for each table and column

            function sortTable(tableId, columnIndex, dataType) {
                const table = document.getElementById(tableId);
                const tbody = table.querySelector('tbody');
                const rows = Array.from(tbody.querySelectorAll('tr'));

                // Determine sort direction
                const sortKey = tableId + '_' + columnIndex;
                const currentDirection = sortDirections[sortKey] || 'asc';
                const newDirection = currentDirection === 'asc' ? 'desc' : 'asc';
                sortDirections[sortKey] = newDirection;

                // Update sort icons
                updateSortIcons(tableId, columnIndex, newDirection);

                // Sort rows
                rows.sort((a, b) => {
                    let valueA = a.cells[columnIndex].textContent.trim();
                    let valueB = b.cells[columnIndex].textContent.trim();

                    // Handle different data types
                    if (dataType === 'number') {
                        // Extract numeric values
                        valueA = parseFloat(valueA.replace(/[^\d.-]/g, '')) || 0;
                        valueB = parseFloat(valueB.replace(/[^\d.-]/g, '')) || 0;

                        if (newDirection === 'asc') {
                            return valueA - valueB;
                        } else {
                            return valueB - valueA;
                        }
                    } else if (dataType === 'date') {
                        // Handle date parsing
                        const datePartsA = valueA.split(' ');
                        const datePartsB = valueB.split(' ');
                        
                        // Convert to Date objects if possible
                        const dateA = new Date(valueA);
                        const dateB = new Date(valueB);
                        
                        if (!isNaN(dateA) && !isNaN(dateB)) {
                            if (newDirection === 'asc') {
                                return dateA - dateB;
                            } else {
                                return dateB - dateA;
                            }
                        }
                        
                        // Fallback to string comparison
                        valueA = valueA.toLowerCase();
                        valueB = valueB.toLowerCase();
                    } else {
                        // String comparison (case-insensitive)
                        valueA = valueA.toLowerCase();
                        valueB = valueB.toLowerCase();
                    }
                    
                    if (newDirection === 'asc') {
                        return valueA.localeCompare(valueB);
                    } else {
                        return valueB.localeCompare(valueA);
                    }
                });

                // Re-append sorted rows
                rows.forEach(row => tbody.appendChild(row));

                // Add visual feedback
                animateTableSort(tableId);
            }

            function updateSortIcons(tableId, activeColumn, direction) {
                const table = document.getElementById(tableId);
                const headers = table.querySelectorAll('th.sortable');

                headers.forEach((header, index) => {
                    const icon = header.querySelector('i');
                    if (index === activeColumn) {
                        // Active column
                        icon.className = direction === 'asc' ? 'fa fa-sort-up' : 'fa fa-sort-down';
                        header.style.color = '#667eea';
                    } else {
                        // Inactive columns
                        icon.className = 'fa fa-sort';
                        header.style.color = '';
                    }
                });
            }

            function animateTableSort(tableId) {
                const table = document.getElementById(tableId);
                table.style.opacity = '0.7';
                setTimeout(() => {
                    table.style.opacity = '1';
                }, 200);
            }

            $(document).ready(function () {
                // Debug: List all appointment rows and their data-id attributes
                console.log("Debugging appointment rows:");
                document.querySelectorAll('tr.appointment-row').forEach(row => {
                    console.log("Row data-id:", row.getAttribute('data-id'));
                });
                
                // Add a listener for when the modal is about to be shown
                $('#viewDetailsModal').on('show.bs.modal', function () {
                    console.log("Modal about to be shown - no resets applied");
                });
                
                // Add a listener for when the modal is shown
                $('#viewDetailsModal').on('shown.bs.modal', function () {
                    console.log("Modal shown, checking elements:");
                    console.log("Status badge element:", document.getElementById('view-status-badge'));
                    console.log("Date time element:", document.getElementById('view-datetime'));
                });
                
                setTimeout(function () {
                    $('.alert').fadeOut();
                }, 5000);

                // Initialize tooltips
                $('[data-toggle="tooltip"]').tooltip();
            });
        </script>
    </body>
</html>
