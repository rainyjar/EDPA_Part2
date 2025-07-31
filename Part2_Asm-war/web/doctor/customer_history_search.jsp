<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="model.Doctor" %>

<%
    // Check if doctor is logged in
    Doctor loggedInDoctor = (Doctor) session.getAttribute("doctor");

    if (loggedInDoctor == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <title>Customer History Search - APU Medical Center</title>
    <%@ include file="/includes/head.jsp" %>
</head>

<body id="top" data-spy="scroll" data-target=".navbar-collapse" data-offset="50">

    <%@ include file="/includes/preloader.jsp" %>
    <%@ include file="/includes/header.jsp" %>
    <%@ include file="/includes/navbar.jsp" %>

    <div class="container mt-4">
        <div class="row">
            <div class="col-md-10 offset-md-1">
                <div class="card">
                    <div class="card-header">
                        <h3><i class="fa fa-search"></i> Customer History Search</h3>
                        <p class="mb-0 text-muted">Search for customer appointment history and medical records</p>
                    </div>
                    <div class="card-body">
                        
                        <!-- Search Section -->
                        <div class="row mb-4">
                            <div class="col-md-8">
                                <div class="form-group">
                                    <label for="customer_search">Search Customer:</label>
                                    <div class="input-group">
                                        <input type="text" class="form-control form-control-lg" id="customer_search" 
                                               placeholder="Enter customer name, email, phone number, or ID">
                                        <div class="input-group-append">
                                            <button type="button" class="btn btn-primary" id="search_btn">
                                                <i class="fa fa-search"></i> Search
                                            </button>
                                        </div>
                                    </div>
                                    <small class="form-text text-muted">
                                        You can search by customer name, email, phone, or customer ID
                                    </small>
                                </div>
                            </div>
                            <div class="col-md-4">
                                <div class="form-group">
                                    <label for="history_filter">Show:</label>
                                    <select class="form-control" id="history_filter">
                                        <option value="all">All Appointments</option>
                                        <option value="past">Past Appointments</option>
                                        <option value="current">Current Appointments</option>
                                        <option value="future">Future Appointments</option>
                                        <option value="completed">Completed</option>
                                        <option value="cancelled">Cancelled</option>
                                    </select>
                                </div>
                            </div>
                        </div>

                        <!-- Search Results -->
                        <div id="search_results_section" style="display:none;">
                            <hr>
                            <h5>Search Results:</h5>
                            <div id="customer_search_results" class="list-group mb-3"></div>
                        </div>

                        <!-- Customer Details and History -->
                        <div id="customer_details_section" style="display:none;">
                            <hr>
                            
                            <!-- Customer Information -->
                            <div class="row mb-4">
                                <div class="col-md-6">
                                    <div class="card border-primary">
                                        <div class="card-header bg-primary text-white">
                                            <h6 class="mb-0"><i class="fa fa-user"></i> Customer Information</h6>
                                        </div>
                                        <div class="card-body" id="customer_info_display">
                                            <!-- Customer info will be loaded here -->
                                        </div>
                                    </div>
                                </div>
                                <div class="col-md-6">
                                    <div class="card border-info">
                                        <div class="card-header bg-info text-white">
                                            <h6 class="mb-0"><i class="fa fa-chart-bar"></i> Appointment Summary</h6>
                                        </div>
                                        <div class="card-body" id="appointment_summary">
                                            <!-- Appointment summary will be loaded here -->
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <!-- Appointment History Table -->
                            <div class="card">
                                <div class="card-header">
                                    <h6 class="mb-0"><i class="fa fa-history"></i> Appointment History</h6>
                                </div>
                                <div class="card-body">
                                    <div class="table-responsive">
                                        <table class="table table-striped table-hover" id="history_table">
                                            <thead class="thead-dark">
                                                <tr>
                                                    <th>Date</th>
                                                    <th>Time</th>
                                                    <th>Treatment</th>
                                                    <th>Doctor</th>
                                                    <th>Status</th>
                                                    <th>Messages</th>
                                                </tr>
                                            </thead>
                                            <tbody id="history_table_body">
                                                <!-- History rows will be loaded here -->
                                            </tbody>
                                        </table>
                                    </div>
                                </div>
                            </div>
                        </div>

                    </div>
                </div>
            </div>
        </div>
    </div>

    <script>
        $(document).ready(function() {
            
            // Search on Enter key or button click
            $('#customer_search').keypress(function(e) {
                if (e.which == 13) {
                    performCustomerSearch();
                }
            });
            
            $('#search_btn').click(function() {
                performCustomerSearch();
            });
            
            // Filter change triggers history reload if customer is selected
            $('#history_filter').change(function() {
                const selectedCustomerId = $('#customer_details_section').data('customer-id');
                if (selectedCustomerId) {
                    loadCustomerHistory(selectedCustomerId, $(this).val());
                }
            });
            
            function performCustomerSearch() {
                const searchTerm = $('#customer_search').val().trim();
                
                if (searchTerm.length < 2) {
                    alert('Please enter at least 2 characters to search');
                    return;
                }
                
                // Show loading
                $('#search_results_section').show();
                $('#customer_search_results').html('<div class="text-center p-3"><i class="fa fa-spinner fa-spin"></i> Searching...</div>');
                
                $.ajax({
                    url: '../CustomerServlet',
                    method: 'GET',
                    data: {
                        action: 'search',
                        search: searchTerm,
                        type: 'all',
                        includeHistory: 'true'
                    },
                    success: function(data) {
                        if (data.error) {
                            $('#customer_search_results').html('<div class="alert alert-danger">' + data.error + '</div>');
                        } else {
                            displaySearchResults(data.customers);
                        }
                    },
                    error: function() {
                        $('#customer_search_results').html('<div class="alert alert-danger">Search failed. Please try again.</div>');
                    }
                });
            }
            
            function displaySearchResults(customers) {
                const resultsDiv = $('#customer_search_results');
                resultsDiv.empty();
                
                if (customers && customers.length > 0) {
                    customers.forEach(function(customer) {
                        const appointmentInfo = customer.appointmentCount !== undefined ? 
                            ' (' + customer.appointmentCount + ' appointments)' : '';
                        const lastAppointment = customer.lastAppointment ? 
                            ', Last: ' + customer.lastAppointment : '';
                        
                        const item = $('<a href="#" class="list-group-item list-group-item-action">')
                            .html(
                                '<div class="d-flex w-100 justify-content-between">' +
                                '<h6 class="mb-1">' + customer.name + '</h6>' +
                                '<small class="text-muted">' + customer.email + '</small>' +
                                '</div>' +
                                '<p class="mb-1">' + customer.phoneNumber + appointmentInfo + '</p>' +
                                '<small class="text-muted">DOB: ' + (customer.dateOfBirth || 'Not specified') + lastAppointment + '</small>'
                            )
                            .click(function(e) {
                                e.preventDefault();
                                selectCustomerForHistory(customer);
                            });
                        
                        resultsDiv.append(item);
                    });
                } else {
                    resultsDiv.html('<div class="alert alert-info">No customers found matching your search</div>');
                }
            }
            
            function selectCustomerForHistory(customer) {
                // Store customer ID for filter changes
                $('#customer_details_section').data('customer-id', customer.id);
                
                // Display customer information
                displayCustomerInfo(customer);
                
                // Load appointment history with current filter
                const filter = $('#history_filter').val();
                loadCustomerHistory(customer.id, filter);
                
                // Show customer details section
                $('#customer_details_section').show();
                
                // Scroll to customer details
                $('html, body').animate({
                    scrollTop: $("#customer_details_section").offset().top - 100
                }, 500);
            }
            
            function displayCustomerInfo(customer) {
                const infoHtml = 
                    '<p><strong>Name:</strong> ' + customer.name + '</p>' +
                    '<p><strong>Email:</strong> ' + customer.email + '</p>' +
                    '<p><strong>Phone:</strong> ' + customer.phoneNumber + '</p>' +
                    '<p><strong>Address:</strong> ' + (customer.address || 'Not specified') + '</p>' +
                    '<p><strong>Gender:</strong> ' + (customer.gender || 'Not specified') + '</p>' +
                    '<p><strong>Date of Birth:</strong> ' + (customer.dateOfBirth || 'Not specified') + '</p>';
                
                $('#customer_info_display').html(infoHtml);
            }
            
            function loadCustomerHistory(customerId, filter) {
                // Show loading in appointment summary
                $('#appointment_summary').html('<div class="text-center"><i class="fa fa-spinner fa-spin"></i> Loading...</div>');
                $('#history_table_body').html('<tr><td colspan="6" class="text-center"><i class="fa fa-spinner fa-spin"></i> Loading appointment history...</td></tr>');
                
                $.ajax({
                    url: '../CustomerServlet',
                    method: 'GET',
                    data: {
                        action: 'history',
                        customerId: customerId,
                        status: filter
                    },
                    success: function(data) {
                        if (data.error) {
                            $('#appointment_summary').html('<div class="alert alert-danger">' + data.error + '</div>');
                            $('#history_table_body').html('<tr><td colspan="6" class="text-center text-danger">Error loading history</td></tr>');
                        } else {
                            displayAppointmentSummary(data.appointments);
                            displayAppointmentHistory(data.appointments);
                        }
                    },
                    error: function() {
                        $('#appointment_summary').html('<div class="alert alert-danger">Failed to load appointment summary</div>');
                        $('#history_table_body').html('<tr><td colspan="6" class="text-center text-danger">Failed to load appointment history</td></tr>');
                    }
                });
            }
            
            function displayAppointmentSummary(appointments) {
                const total = appointments.length;
                const completed = appointments.filter(apt => apt.status === 'completed').length;
                const cancelled = appointments.filter(apt => apt.status === 'cancelled').length;
                const pending = appointments.filter(apt => apt.status === 'pending').length;
                const approved = appointments.filter(apt => apt.status === 'approved').length;
                
                const summaryHtml = 
                    '<p><strong>Total Appointments:</strong> ' + total + '</p>' +
                    '<p><strong>Completed:</strong> ' + completed + '</p>' +
                    '<p><strong>Cancelled:</strong> ' + cancelled + '</p>' +
                    '<p><strong>Pending:</strong> ' + pending + '</p>' +
                    '<p><strong>Approved:</strong> ' + approved + '</p>';
                
                $('#appointment_summary').html(summaryHtml);
            }
            
            function displayAppointmentHistory(appointments) {
                const tbody = $('#history_table_body');
                tbody.empty();
                
                if (appointments && appointments.length > 0) {
                    appointments.forEach(function(appointment) {
                        const statusClass = getStatusBadgeClass(appointment.status);
                        const messagesHtml = buildMessagesColumn(appointment);
                        
                        const row = 
                            '<tr>' +
                            '<td>' + appointment.appointmentDate + '</td>' +
                            '<td>' + appointment.appointmentTime + '</td>' +
                            '<td>' + (appointment.treatment || 'N/A') + '</td>' +
                            '<td>' + (appointment.doctor || 'Not assigned') + '</td>' +
                            '<td><span class="badge badge-' + statusClass + '">' + appointment.status + '</span></td>' +
                            '<td>' + messagesHtml + '</td>' +
                            '</tr>';
                        
                        tbody.append(row);
                    });
                } else {
                    tbody.html('<tr><td colspan="6" class="text-center text-muted">No appointments found</td></tr>');
                }
            }
            
            function getStatusBadgeClass(status) {
                switch (status) {
                    case 'completed': return 'success';
                    case 'approved': return 'primary';
                    case 'pending': return 'warning';
                    case 'cancelled': return 'danger';
                    case 'overdue': return 'dark';
                    default: return 'secondary';
                }
            }
            
            function buildMessagesColumn(appointment) {
                let messages = [];
                
                if (appointment.custMessage) {
                    messages.push('<small><strong>Customer:</strong> ' + appointment.custMessage + '</small>');
                }
                if (appointment.docMessage) {
                    messages.push('<small><strong>Doctor:</strong> ' + appointment.docMessage + '</small>');
                }
                if (appointment.staffMessage) {
                    messages.push('<small><strong>Staff:</strong> ' + appointment.staffMessage + '</small>');
                }
                
                return messages.length > 0 ? messages.join('<br>') : '<span class="text-muted">No messages</span>';
            }
        });
    </script>

    <%@ include file="/includes/footer.jsp" %>
    <%@ include file="/includes/scripts.jsp" %>

    <style>
        .card-header {
            font-weight: 500;
        }
        
        .list-group-item:hover {
            background-color: #f8f9fa;
        }
        
        .badge {
            font-size: 0.8em;
        }
        
        #history_table th {
            font-size: 0.9em;
            font-weight: 600;
        }
        
        #history_table td {
            font-size: 0.85em;
            vertical-align: middle;
        }
        
        .fa-spinner {
            animation: spin 1s linear infinite;
        }
    </style>

</body>
</html>
