<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="model.Appointment" %>
<%@ page import="model.Doctor" %>
<%
    Doctor doctor = (Doctor) session.getAttribute("doctor");
    if (doctor == null) {
        response.sendRedirect("../login.jsp");
        return;
    }
    List<Appointment> appointments = (List<Appointment>) request.getAttribute("appointments");
%>
<!DOCTYPE html>
<html lang="en">
    <head>
        <title>My Tasks - AMC Healthcare System</title>

        <%@ include file="/includes/head.jsp" %>
        <link rel="stylesheet" href="<%= request.getContextPath()%>/css/manager-homepage.css">
        <link rel="stylesheet" href="<%= request.getContextPath()%>/css/manage-staff.css">

        <style>
            @media (max-width: 768px) {
                .search-form .form-row {
                    flex-direction: column;
                }

                .search-form .form-group {
                    width: 100%;
                    min-width: unset;
                }
            }

            .status-badge {
                padding: 4px 8px;
                border-radius: 4px;
                font-size: 12px;
                font-weight: bold;
            }

            .status-approved {
                background-color: #28a745;
                color: white;
            }

            .status-completed {
                background-color: #6c757d;
                color: white;
            }

            .complete-appointment-modal .modal-content {
                border-radius: 10px;
            }

            .complete-appointment-modal .modal-header {
                background: linear-gradient(135deg, #007bff, #0056b3);
                color: white;
                border-radius: 10px 10px 0 0;
            }

            .btn-complete {
                background: linear-gradient(135deg, #28a745, #20c997);
                border: none;
                color: white;
                transition: all 0.3s ease;
            }

            .btn-complete:hover {
                transform: translateY(-2px);
                box-shadow: 0 4px 12px rgba(40, 167, 69, 0.3);
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
                            <i class="fa fa-tasks" style="color:white"></i>
                            <span style="color:white">My Tasks</span>
                        </h1>
                        <p class="lead wow fadeInUp" data-wow-delay="0.2s" style="color: whitesmoke">
                            View and complete your approved appointments
                        </p>
                        <nav aria-label="breadcrumb" class="wow fadeInUp" data-wow-delay="0.3s">
                            <ol class="breadcrumb" style="background: transparent; margin: 0;">
                                <li class="breadcrumb-item">
                                    <a href="<%= request.getContextPath()%>/DoctorHomepageServlet" style="color: rgba(255,255,255,0.8);">Dashboard</a> 
                                </li>
                                <li class="breadcrumb-item active" style="color: white;">My Tasks</li>
                            </ol>
                        </nav>
                    </div>
                </div>
            </div>
        </section>

        <section style="padding: 40px 0; background: #f5f5f5;">
            <div class="container">
                <!-- Success/Error Messages -->
                <% String successParam = request.getParameter("success"); %>
                <% if (successParam != null) {%>
                <div class="alert alert-success alert-dismissible">
                    <button type="button" class="close" data-dismiss="alert">&times;</button>
                    <i class="fa fa-check-circle"></i> <%= successParam%>
                </div>
                <% } %>

                <% String errorParam = request.getParameter("error"); %>
                <% if (errorParam != null) {%>
                <div class="alert alert-danger alert-dismissible">
                    <button type="button" class="close" data-dismiss="alert">&times;</button>
                    <i class="fa fa-exclamation-triangle"></i> <%= errorParam%>
                </div>
                <% }%>

                <!-- SEARCH AND FILTER SECTION -->
                <div class="search-filter-section wow fadeInUp" data-wow-delay="0.2s">
                    <h3><i class="fa fa-search"></i> Search & Filter Appointments</h3>

                    <form method="GET" action="<%= request.getContextPath()%>/TreatmentServlet" class="search-form">
                        <input type="hidden" name="action" value="myTasks">

                        <div class="form-row">
                            <div class="form-group">
                                <label for="searchQuery">Search by Patient Name/Treatment</label>
                                <input type="text" class="form-control" id="searchQuery" name="searchQuery" 
                                       placeholder="Enter patient name or treatment..." onkeyup="filterAppointments()"
                                       value="<%= request.getParameter("searchQuery") != null ? request.getParameter("searchQuery") : ""%>">
                            </div>

                            <div class="form-group">
                                <label for="dateFilter">Filter by Date</label>
                                <%
                                    String dateFilterParam = request.getParameter("dateFilter");
                                    String dateFilter = "";
                                    if (dateFilterParam != null && dateFilterParam.matches("\\d{4}-\\d{2}-\\d{2}")) {
                                        dateFilter = dateFilterParam;
                                    }
                                %>
                                <input type="date" class="form-control" id="dateFilter" name="dateFilter"
                                       onchange="filterAppointments()"
                                       value="<%= dateFilter%>">

                            </div>
                        </div>

                        <div id="resultsInfo" class="text-muted small" style="margin-top: 5px;">
                            Showing all approved appointments
                        </div>

                        <div class="form-group">
                            <button type="button" class="btn btn-secondary" onclick="clearFilters()">
                                <i class="fa fa-refresh"></i> Clear Filters
                            </button>
                            <a href="<%= request.getContextPath()%>/TreatmentServlet?action=viewAppointmentHistory" class="btn btn-primary">
                                <i class="fa fa-history"></i> View All Appointment History
                            </a>
                        </div>

                    </form>
                </div>

                <!-- APPOINTMENTS SECTION -->
                <div class="staff-management-section wow fadeInUp" data-wow-delay="0.4s">
                    <div class="d-flex justify-content-between align-items-center mb-4">
                        <div>
                            <h3><i class="fa fa-calendar-check"></i> My Tasks</h3>
                        </div>
                    </div>

                    <!-- Appointments Table -->
                    <div class="staff-table">
                        <%  if (appointments != null && !appointments.isEmpty()) { %>

                        <table class="table table-hover" id="appointmentsTable">
                            <thead>
                                <tr>
                                    <th class="sortable" onclick="sortTable('appointmentsTable', 0, 'number')">
                                        ID <i class="fa fa-sort"></i>
                                    </th>
                                    <th class="sortable" onclick="sortTable('appointmentsTable', 1, 'string')">
                                        Patient Name <i class="fa fa-sort"></i>
                                    </th>
                                    <th class="sortable" onclick="sortTable('appointmentsTable', 2, 'string')">
                                        Treatment <i class="fa fa-sort"></i>
                                    </th>
                                    <th class="sortable" onclick="sortTable('appointmentsTable', 3, 'date')">
                                        Date & Time <i class="fa fa-sort"></i>
                                    </th>
                                    <th>Patient Message</th>
                                    <th>Actions</th>
                                </tr>
                            </thead>
                            <tbody>
                                <%
                                    SimpleDateFormat dateFormat = new SimpleDateFormat("dd/MM/yyyy");
                                    SimpleDateFormat timeFormat = new SimpleDateFormat("HH:mm");
                                    for (Appointment appointment : appointments) {
                                %>
                                <tr>
                                    <td><%= appointment.getId()%></td>
                                    <td><strong><%= appointment.getCustomer() != null ? appointment.getCustomer().getName() : "N/A"%></strong></td>
                                    <td><%= appointment.getTreatment() != null ? appointment.getTreatment().getName() : "N/A"%></td>
                                    <td>
                                        <%= appointment.getAppointmentDate() != null ? dateFormat.format(appointment.getAppointmentDate()) : "N/A"%><br>
                                        <small class="text-muted"><%= appointment.getAppointmentTime() != null ? timeFormat.format(appointment.getAppointmentTime()) : "N/A"%></small>
                                    </td>
                                    <td>
                                        <%
                                            String custMessage = appointment.getCustMessage();
                                            if (custMessage != null && custMessage.length() > 50) {
                                                out.print(custMessage.substring(0, 50) + "...");
                                            } else {
                                                out.print(custMessage != null ? custMessage : "No message");
                                            }
                                        %>
                                    </td>
                                    <td>
                                        <div class="action-buttons">
                                            <button class="btn btn-sm btn-complete" 
                                                    data-appointment-id="<%= appointment.getId()%>" 
                                                    data-patient-name="<%= appointment.getCustomer() != null ? appointment.getCustomer().getName() : "N/A"%>"
                                                    onclick="showCompleteModal(this)" 
                                                    title="Mark as Completed">
                                                <i class="fa fa-check"></i> Complete
                                            </button>
                                        </div>
                                    </td>
                                </tr>
                                <% } %>
                            </tbody>
                        </table>
                        <% } else {%>

                        <div class="no-data">
                            <i class="fa fa-calendar-check-o"></i>
                            <h4>Congratulations, you have completed all your tasks!</h4>
                            <p>There are no approved appointments waiting to be completed.</p>
                        </div>
                        <% }%>
                    </div>
                </div>
            </div>
        </section>

        <!-- Complete Appointment Modal -->
        <div class="modal fade complete-appointment-modal" id="completeAppointmentModal" tabindex="-1" role="dialog">
            <div class="modal-dialog" role="document">
                <div class="modal-content">
                    <div class="modal-header">
                        <h5 class="modal-title">
                            <i class="fa fa-check-circle"></i> Complete Appointment
                        </h5>
                        <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                            <span aria-hidden="true" style="color: white;">&times;</span>
                        </button>
                    </div>
                    <form method="post" action="<%= request.getContextPath()%>/TreatmentServlet">
                        <div class="modal-body">
                            <input type="hidden" name="action" value="completeAppointment">
                            <input type="hidden" name="appointmentId" id="modalAppointmentId">

                            <div class="alert alert-info">
                                <i class="fa fa-info-circle"></i>
                                <strong>Patient:</strong> <span id="modalPatientName"></span>
                            </div>

                            <div class="form-group">
                                <label for="docMessage">Doctor's Notes (Optional)</label>
                                <textarea class="form-control" id="docMessage" name="docMessage" rows="4" 
                                          placeholder="Add any notes about the appointment completion..."></textarea>
                            </div>
                        </div>
                        <div class="modal-footer">
                            <button type="button" class="btn btn-secondary" data-dismiss="modal">Cancel</button>
                            <button type="submit" class="btn btn-complete">
                                <i class="fa fa-check"></i> Mark as Completed
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>

        <%@ include file="/includes/footer.jsp" %>
        <%@ include file="/includes/scripts.jsp" %>

        <script>
            // Show complete appointment modal
            function showCompleteModal(button) {
                var appointmentId = button.getAttribute('data-appointment-id');
                var patientName = button.getAttribute('data-patient-name');

                $('#modalAppointmentId').val(appointmentId);
                $('#modalPatientName').text(patientName);
                $('#completeAppointmentModal').modal('show');
            }

            // Filter appointments function
            function filterAppointments() {
                var searchQuery = document.getElementById('searchQuery').value.toLowerCase();
                var dateFilter = document.getElementById('dateFilter').value;
                var table = document.getElementById('appointmentsTable');
                var rows = table.getElementsByTagName('tbody')[0].getElementsByTagName('tr');
                var visibleCount = 0;

                for (var i = 0; i < rows.length; i++) {
                    var row = rows[i];
                    var patientName = row.cells[1].textContent.toLowerCase();
                    var treatment = row.cells[2].textContent.toLowerCase();
                    var dateTime = row.cells[3].textContent;

                    var matchesSearch = searchQuery === '' ||
                            patientName.includes(searchQuery) ||
                            treatment.includes(searchQuery);

                    var matchesDate = dateFilter === '' || dateTime.includes(formatDateForFilter(dateFilter));

                    if (matchesSearch && matchesDate) {
                        row.style.display = '';
                        visibleCount++;
                    } else {
                        row.style.display = 'none';
                    }
                }

                // Update results info
                var resultsInfo = document.getElementById('resultsInfo');
                if (searchQuery || dateFilter) {
                    resultsInfo.textContent = 'Showing ' + visibleCount + ' of ' + rows.length + ' approved appointments';
                } else {
                    resultsInfo.textContent = 'Showing all approved appointments';
                }
            }

            // Clear all filters
            function clearFilters() {
                document.getElementById('searchQuery').value = '';
                document.getElementById('dateFilter').value = '';
                filterAppointments();
            }

            // Format date for filtering
            function formatDateForFilter(dateString) {
                var date = new Date(dateString);
                var day = String(date.getDate()).padStart(2, '0');
                var month = String(date.getMonth() + 1).padStart(2, '0');
                var year = date.getFullYear();
                return day + '/' + month + '/' + year;
            }

            // Table sorting function (from manage-staff.css/js)
            function sortTable(tableId, columnIndex, dataType) {
                var table = document.getElementById(tableId);
                var tbody = table.tBodies[0];
                var rows = Array.from(tbody.rows);
                var isAscending = table.getAttribute('data-sort-direction') !== 'asc';

                rows.sort(function (rowA, rowB) {
                    var cellA = rowA.cells[columnIndex].textContent.trim();
                    var cellB = rowB.cells[columnIndex].textContent.trim();

                    if (dataType === 'number') {
                        return isAscending ?
                                parseFloat(cellA) - parseFloat(cellB) :
                                parseFloat(cellB) - parseFloat(cellA);
                    } else if (dataType === 'date') {
                        var dateA = new Date(cellA.split('\n')[0].split('/').reverse().join('-'));
                        var dateB = new Date(cellB.split('\n')[0].split('/').reverse().join('-'));
                        return isAscending ? dateA - dateB : dateB - dateA;
                    } else {
                        return isAscending ?
                                cellA.localeCompare(cellB) :
                                cellB.localeCompare(cellA);
                    }
                });

                // Re-append sorted rows
                rows.forEach(function (row) {
                    tbody.appendChild(row);
                });

                // Update sort direction
                table.setAttribute('data-sort-direction', isAscending ? 'asc' : 'desc');

                // Update sort icons
                var headers = table.querySelectorAll('th.sortable i');
                headers.forEach(function (icon) {
                    icon.className = 'fa fa-sort';
                });

                var currentHeader = table.querySelectorAll('th.sortable')[columnIndex].querySelector('i');
                currentHeader.className = isAscending ? 'fa fa-sort-up' : 'fa fa-sort-down';
            }

            // Auto-hide alerts after 5 seconds
            setTimeout(function () {
                $('.alert').fadeOut('slow');
            }, 5000);
        </script>
    </body>
</html>
