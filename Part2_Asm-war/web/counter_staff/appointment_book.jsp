<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="model.CounterStaff" %>
<%@ page import="model.Doctor" %>
<%@ page import="model.Treatment" %>
<%@ page import="model.Customer" %>

<%
    // Check if counter staff is logged in
    CounterStaff loggedInStaff = (CounterStaff) session.getAttribute("staff");

    if (loggedInStaff == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    } else {
        System.out.println("Counter Staff " + loggedInStaff.getName() + " logged in successfully!");
    }
    
    // Get data from servlet
    List<Doctor> doctorList = (List<Doctor>) request.getAttribute("doctorList");
    List<Treatment> treatmentList = (List<Treatment>) request.getAttribute("treatmentList");
    
    // Get pre-selected treatment ID if coming from treatment page
    String preSelectedTreatment = request.getParameter("treatment_id");
%>

<!DOCTYPE html>
<html lang="en">

<head>
    <title>Book Appointment for Customer - APU Medical Center</title>
    <%@ include file="/includes/head.jsp" %>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/css/staff-appointment-booking.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/user-reg-edit.css" />

</head>

<body id="top" data-spy="scroll" data-target=".navbar-collapse" data-offset="50">

    <%--<%@ include file="/includes/preloader.jsp" %>--%>
    <%@ include file="/includes/header.jsp" %>
    <%@ include file="/includes/navbar.jsp" %>

    <!-- APPOINTMENT SECTION -->
    <section class="appointment-container staff-booking">
        <div class="container">
            <div class="row">
                <a href="${pageContext.request.contextPath}/CounterStaffServletJam?action=dashboard" class="back-btn" style="margin-bottom: 30px">
                    <i class="fa fa-arrow-left"></i> Back to Dashboard
                </a>
                <div class="col-md-8 col-md-offset-2">
                    <img src="<%= request.getContextPath() %>/images/cust_homepage/appointment-image.jpg" class="img-responsive">
                    <div class="appointment-form-wrapper">
                        
                        <!-- Error and Success Messages (Customer-style) -->
                        <%
                            String errorParam = request.getParameter("error");
                            String successParam = request.getParameter("success");
                        %>
                        <% if (errorParam != null) { %>
                            <div class="alert alert-danger alert-dismissible" role="alert">
                                <button type="button" class="close" data-dismiss="alert">&times;</button>
                                <i class="fa fa-exclamation-circle"></i>
                                <% if ("missing_customer".equals(errorParam)) { %>
                                    Please select a customer.
                                <% } else if ("customer_not_found".equals(errorParam)) { %>
                                    Customer not found.
                                <% } else if ("invalid_customer_id".equals(errorParam)) { %>
                                    Invalid customer ID.
                                <% } else if ("missing_treatment".equals(errorParam)) { %>
                                    Please select a treatment.
                                <% } else if ("missing_doctor".equals(errorParam)) { %>
                                    Please select a doctor.
                                <% } else if ("missing_date".equals(errorParam)) { %>
                                    Please select an appointment date.
                                <% } else if ("missing_time".equals(errorParam)) { %>
                                    Please select an appointment time.
                                <% } else if ("invalid_selection".equals(errorParam)) { %>
                                    Invalid treatment or doctor selection. Please try again.
                                <% } else if ("invalid_date".equals(errorParam)) { %>
                                    Please select a future date for your appointment (weekdays only, within the next week).
                                <% } else if ("invalid_time".equals(errorParam)) { %>
                                    Please select a valid time slot (9:00 AM - 5:00 PM, 30-minute intervals).
                                <% } else if ("time_conflict".equals(errorParam)) { %>
                                    The selected time slot is not available. Please choose another time.
                                <% } else if ("booking_failed".equals(errorParam)) { %>
                                    Booking failed. Please try again or contact support.
                                <% } else if ("invalid_data".equals(errorParam)) { %>
                                    Invalid data provided. Please check your selections.
                                <% } else if ("invalid_datetime".equals(errorParam)) { %>
                                    Invalid date or time format. Please try again.
                                <% } else if ("load_failed".equals(errorParam)) { %>
                                    Failed to load appointment data. Please refresh the page.
                                <% } else { %>
                                    An error occurred: <%= errorParam %>
                                <% } %>
                            </div>
                        <% } %>
                        <% if (successParam != null) { %>
                            <div class="alert alert-success alert-dismissible" role="alert">
                                <button type="button" class="close" data-dismiss="alert">&times;</button>
                                <i class="fa fa-check-circle"></i>
                                <% if ("appointment_booked".equals(successParam)) { %>
                                    Appointment booked successfully!
                                <% } else if ("booked".equals(successParam)) { %>
                                    Appointment booked successfully! The customer has been notified.
                                <% } %>
                            </div>
                        <% } %>

                        <!-- Step Indicator -->
                        <div class="step-indicator">
                            <div class="step active clickable" id="step0" data-section="customer-section">0. Select Customer</div>
                            <div class="step clickable" id="step1" data-section="treatment-section">1. Select Treatment</div>
                            <div class="step clickable" id="step2" data-section="date-section">2. Choose Date</div>
                            <div class="step clickable" id="step3" data-section="doctor-section">3. Pick Doctor & Time</div>
                            <div class="step clickable" id="step4" data-section="message-section">4. Add Message</div>
                        </div>

                        <!-- Customer Info Display -->
                        <div class="customer-info-display" id="customer-info-display" style="display:none;">
                            <h4><i class="fa fa-user"></i> Booking for:</h4>
                            <div class="row" id="customer-details">
                                <!-- Customer details will be populated here -->
                            </div>
                        </div>

                        <!-- Appointment Form -->
                        <form id="appointment-form" method="post" action="<%= request.getContextPath() %>/AppointmentServlet">
                            <input type="hidden" name="action" value="book">
                            <input type="hidden" name="customer_id" id="selected_customer_id" required>
                            
                            <!-- Step 0: Customer Selection -->
                            <div class="form-section" id="customer-section">
                                <h4 class="section-title"><i class="fa fa-search"></i> Step 0: Search & Select Customer</h4>
                                
                                <div class="form-group">
                                    <label for="customer_search">Search Customer:</label>
                                    <div class="input-group customer-search-container" style="max-width: 100% !important; width: 100% !important;">
                                        <div class="input-group-prepend">
                                            <span class="input-group-text" style="background-color: #667eea !important; color: white !important; border: 2px solid #667eea !important; border-radius: 0 !important; padding: 12px 15px !important; font-size: 16px !important;">
                                                <i class="fa fa-search"></i>
                                            </span>
                                        </div>
                                        <input type="text" class="form-control" id="customer_search" 
                                               placeholder="Enter customer name, email, phone number, or ID"
                                               style="font-size: 16px !important; padding: 12px 15px !important; height: auto !important; line-height: 1.5 !important; border: 2px solid #ddd !important; border-radius: 0 !important; border-left: none !important; flex: 1 !important; min-width: 300px !important;">
                                        <div class="input-group-append">
                                            <button type="button" class="btn btn-outline-secondary" id="clear_search" 
                                                    onclick="clearCustomerSearch()" title="Clear search"
                                                    style="border: 2px solid #ddd !important; border-left: none !important; border-radius: 0 !important; padding: 12px 15px !important; font-size: 16px !important;">
                                                <i class="fa fa-times"></i>
                                            </button>
                                        </div>
                                    </div>
                                    <small class="form-text text-muted">
                                        <i class="fa fa-info-circle"></i> You can search by customer name, email address, phone number, or customer ID. Press Enter to search.
                                    </small>
                                    <div id="customer_results" class="list-group mt-2" style="display:none; position: relative !important; z-index: 1000 !important; width: 100% !important; max-height: 250px !important; overflow-y: auto !important; border: 1px solid #ddd !important; border-radius: 0.375rem !important; background-color: white !important; box-shadow: 0 0.5rem 1rem rgba(0, 0, 0, 0.15) !important; margin-top: 5px !important;"></div>
                                </div>
                                
                                <div class="text-center mt-4">
                                    <div class="alert alert-info customer-not-found-alert">
                                        <i class="fa fa-question-circle"></i>
                                        <strong>Customer not found?</strong><br>
                                        <a href="<%= request.getContextPath() %>/counter_staff/register_customer.jsp" class="btn btn-info btn-sm mt-2">
                                            <i class="fa fa-user-plus"></i> Register New Customer
                                        </a>
                                    </div>
                                </div>
                            </div>
                            
                            <!-- Step 1: Treatment Selection -->
                            <div class="form-section hidden" id="treatment-section">
                                <h4 class="section-title"><i class="fa fa-stethoscope"></i> Step 1: Select Treatment</h4>
                                <div class="form-group">
                                    <label for="treatment">Choose Treatment:</label>
                                    <select id="treatment" name="treatment_id" class="form-control" required>
                                        <option value="" disabled <%= preSelectedTreatment == null ? "selected" : "" %>>Select a treatment...</option>
                                        <% if (treatmentList != null && !treatmentList.isEmpty()) {
                                            for (Treatment treatment : treatmentList) {
                                                String treatmentName = treatment.getName();
                                                if (treatmentName != null && treatmentName.contains("-")) {
                                                    treatmentName = treatmentName.substring(0, treatmentName.indexOf("-")).trim();
                                                }
                                                String selected = "";
                                                if (preSelectedTreatment != null && preSelectedTreatment.equals(String.valueOf(treatment.getId()))) {
                                                    selected = "selected";
                                                }
                                        %>
                                            <option value="<%= treatment.getId() %>" 
                                                    data-base-charge="<%= treatment.getBaseConsultationCharge() %>"
                                                    <%= selected %>>
                                                <%= treatmentName %>
                                            </option>
                                        <% 
                                            }
                                        } else { 
                                        %>
                                            <option value="" disabled>No treatments available</option>
                                        <% } %>
                                    </select>
                                </div>
                            </div>

                            <!-- Step 2: Date Selection -->
                            <div class="form-section hidden" id="date-section">
                                <h4 class="section-title"><i class="fa fa-calendar"></i> Step 2: Select Date</h4>
                                <div class="form-group">
                                    <label for="appointment_date">Choose Date (Weekdays Only):</label>
                                    <input type="date" id="appointment_date" name="appointment_date" class="form-control" required>
                                    <small class="form-text text-muted">
                                        <i class="fa fa-info-circle"></i> 
                                        Available: Monday to Friday, 9:00 AM - 5:00 PM.
                                        <br>Booking window: Today to 7 days ahead (weekdays only selectable). <br>
                                        <strong>Note:</strong> If booking after 5:00 PM today, earliest available date is tomorrow (if weekday).
                                    </small>
                                </div>
                            </div>

                            <!-- Step 3: Doctor & Time Selection -->
                            <div class="form-section hidden" id="doctor-section">
                                <h4 class="section-title"><i class="fa fa-user-md"></i> Step 3: Select Doctor & Time</h4>
                                <div class="form-group">
                                    <label>Available Time Slots (9:00 AM - 5:00 PM):</label><br>
                                    <small class="form-text text-muted" style="margin-bottom: 15px;">
                                        <i class="fa fa-clock-o"></i> 
                                        Each appointment slot is 30 minutes. Business hours: 9:00 AM to 5:00 PM, weekdays only.
                                    </small>
                                </div>
                                <div id="doctor-cards-container">
                                    <!-- Doctor cards will be populated dynamically -->
                                </div>
                                <input type="hidden" id="selected_doctor_id" name="doctor_id" required>
                                <input type="hidden" id="selected_time_slot" name="appointment_time" required>
                            </div>

                            <!-- Step 4: Message -->
                            <div class="form-section hidden" id="message-section">
                                <h4 class="section-title"><i class="fa fa-comment"></i> Step 4: Medical Concerns (Optional)</h4>
                                <div class="form-group">
                                    <label for="staff_message">Describe customer's medical concerns or specific requests:</label>
                                    <textarea id="staff_message" name="staff_message" class="form-control" 
                                             rows="4" placeholder="Please describe the customer's symptoms, concerns, or any specific requests for the consultation..."></textarea>
                                    <small class="form-text text-muted">This information will help the doctor prepare for the consultation.</small>
                                </div>
                                
                                <!-- Submit Section -->
                                <div class="text-center" style="margin-top: 30px;">
                                    <button type="button" id="submit-appointment" class="btn btn-submit btn-lg">
                                        <i class="fa fa-check"></i> Book Appointment for Customer
                                    </button>
                                </div>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- Confirmation Modal -->
    <div class="modal fade" id="confirmationModal" tabindex="-1" role="dialog">
        <div class="modal-dialog modal-lg" role="document">
            <div class="modal-content">
                <div class="modal-header">
                    <h4 class="modal-title"><i class="fa fa-check-circle"></i> Confirm Appointment Booking</h4>
                    <button type="button" class="close" data-dismiss="modal">&times;</button>
                </div>
                <div class="modal-body">
                    <div class="row">
                        <div class="col-md-6">
                            <h5>Patient Information:</h5>
                            <p><strong>Name:</strong> <span id="confirm-customer-name"></span></p>
                            <p><strong>Email:</strong> <span id="confirm-customer-email"></span></p>
                            <p><strong>Phone:</strong> <span id="confirm-customer-phone"></span></p>
                        </div>
                        <div class="col-md-6">
                            <h5>Appointment Details:</h5>
                            <p><strong>Treatment:</strong> <span id="confirm-treatment"></span></p>
                            <p><strong>Doctor:</strong> <span id="confirm-doctor"></span></p>
                            <p><strong>Date:</strong> <span id="confirm-date"></span></p>
                            <p><strong>Time:</strong> <span id="confirm-time"></span></p>
                        </div>
                    </div>
                    
                    <div style="margin-top: 15px;">
                        <h5>Medical Concerns:</h5>
                        <p id="confirm-message" style="font-style: italic; color: #666;"></p>
                    </div>
                    
                    <div class="alert alert-info">
                        <i class="fa fa-info-circle"></i>
                        <strong>Please Note:</strong> The appointment will be booked for the selected customer. 
                        They will be notified of the booking confirmation.
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" id="final-confirm" class="btn btn-success btn-lg">
                        <i class="fa fa-check"></i> Confirm & Book
                    </button>
                    <button type="button" class="btn btn-secondary" data-dismiss="modal">
                        <i class="fa fa-times"></i> Cancel
                    </button>
                </div>
            </div>
        </div>
    </div>

    <%@ include file="/includes/footer.jsp" %>
    <%@ include file="/includes/scripts.jsp" %>
    
    <!-- Pass JSP data to JavaScript -->
    <script>
        // Pass doctor data from JSP to JavaScript
        window.doctorData = [
            <%
            if (doctorList != null && !doctorList.isEmpty()) {
                for (int i = 0; i < doctorList.size(); i++) {
                    Doctor doctor = doctorList.get(i);
                    String doctorName = doctor.getName();
                    String specialization = doctor.getSpecialization();
                    if (doctorName != null) {
                        doctorName = doctorName.replaceAll("'", "\\\\'");
                    }
                    if (specialization == null) {
                        specialization = "";
                    } else {
                        specialization = specialization.replaceAll("'", "\\\\'");
                    }
                    if (i > 0) out.print(",");
            %>
                {
                    id: <%= doctor.getId() %>,
                    name: '<%= doctorName %>',
                    specialization: '<%= specialization %>'
                }
            <%
                }
            }
            %>
        ];
        
        // Pass pre-selected treatment info
        window.preSelectedTreatment = <%= preSelectedTreatment != null ? preSelectedTreatment : "null" %>;
        
        // Store selected customer data
        window.selectedCustomerData = null;
        
        // Counter staff appointment booking with step navigation
        $(document).ready(function() {
            
            // Initialize step navigation
            initializeStepNavigation();
            
            // Initialize date restrictions
            initializeDateRestrictions();
            
            // Customer search functionality - separate handlers for input and keypress
            $('#customer_search').on('input', function(e) {
                const searchTerm = $(this).val().trim();
                if (searchTerm.length >= 2) {
                    searchCustomers(searchTerm);
                } else {
                    $('#customer_results').hide();
                }
            });
            
            // Enter key handler for customer search
            $('#customer_search').on('keypress', function(e) {
                if (e.which === 13) {
                    e.preventDefault();
                    const searchTerm = $(this).val().trim();
                    console.log('Enter key pressed with search term:', searchTerm);
                    if (searchTerm.length >= 1) {
                        searchCustomers(searchTerm);
                    }
                    return false;
                }
            });
            
            // Search customers using CustomerServlet
            function searchCustomers(searchTerm) {
                console.log('=== Frontend Search Debug ===');
                console.log('Searching for:', searchTerm);
                
                // Show loading state
                $('#customer_results').html('<div class="list-group-item text-center"><i class="fa fa-spinner fa-spin"></i> Searching...</div>').show();
                
                const requestData = { 
                    action: 'search',
                    search: searchTerm,
                    type: 'all',
                    includeHistory: 'true'
                };
                
                console.log('Request data:', requestData);
                
                $.ajax({
                    url: '<%= request.getContextPath() %>/CustomerServlet',
                    method: 'GET',
                    data: requestData,
                    dataType: 'json',
                    beforeSend: function(xhr) {
                        xhr.setRequestHeader('Accept', 'application/json');
                        console.log('Request headers set, sending AJAX request...');
                    },
                    success: function(data) {
                        console.log('=== AJAX Success ===');
                        console.log('Raw response:', data);
                        console.log('Response type:', typeof data);
                        
                        if (data.error) {
                            console.error('Server returned error:', data.error);
                            $('#customer_results').html('<div class="list-group-item text-danger"><i class="fa fa-exclamation-circle"></i> ' + data.error + '</div>').show();
                        } else if (data.customers) {
                            console.log('Customers array found, length:', data.customers.length);
                            displayCustomerResults(data.customers);
                        } else {
                            console.warn('Unexpected response format:', data);
                            $('#customer_results').html('<div class="list-group-item text-warning"><i class="fa fa-exclamation-triangle"></i> Unexpected response format</div>').show();
                        }
                    },
                    error: function(xhr, status, error) {
                        console.error('=== AJAX Error ===');
                        console.error('XHR Status:', xhr.status);
                        console.error('Status Text:', xhr.statusText);
                        console.error('Error:', error);
                        console.error('Response Text:', xhr.responseText);
                        
                        let errorMsg = 'Search failed. ';
                        if (xhr.status === 0) {
                            errorMsg += 'Unable to connect to server.';
                        } else if (xhr.status === 404) {
                            errorMsg += 'Service not found (404).';
                        } else if (xhr.status === 500) {
                            errorMsg += 'Server error (500).';
                        } else {
                            errorMsg += 'Status: ' + xhr.status;
                        }
                        
                        $('#customer_results').html('<div class="list-group-item text-danger"><i class="fa fa-exclamation-circle"></i> ' + errorMsg + '</div>').show();
                    }
                });
            }
            
            function displayCustomerResults(customers) {
                console.log('Displaying customer results:', customers);
                const resultsDiv = $('#customer_results');
                resultsDiv.empty();
                
                if (customers && customers.length > 0) {
                    customers.forEach(function(customer) {
                        const customerInfo = customer.name + ' - ' + customer.email;
                        const customerSubInfo = customer.phoneNumber + 
                            (customer.appointmentCount !== undefined ? ' (' + customer.appointmentCount + ' appointments)' : '');
                        
                        const item = $('<a href="#" class="list-group-item list-group-item-action">')
                            .html('<div><strong>' + customerInfo + '</strong></div><small class="text-muted">' + customerSubInfo + '</small>')
                            .data('customer', customer)
                            .click(function(e) {
                                e.preventDefault();
                                console.log('Customer selected:', customer);
                                selectCustomer(customer);
                            });
                        resultsDiv.append(item);
                    });
                    resultsDiv.show();
                    console.log('Results displayed, showing div');
                } else {
                    const noResults = $('<div class="list-group-item text-muted">')
                        .html('<i class="fa fa-info-circle"></i> No customers found matching your search');
                    resultsDiv.append(noResults);
                    resultsDiv.show();
                    
                    setTimeout(function() {
                        resultsDiv.hide();
                    }, 3000);
                }
            }
            
            function selectCustomer(customer) {
                // Store customer data globally
                window.selectedCustomerData = customer;
                
                // Set hidden field
                $('#selected_customer_id').val(customer.id);
                
                // Display customer info
                displaySelectedCustomer(customer);
                
                // Hide search results and clear search input
                $('#customer_results').hide();
                $('#customer_search').val('');
                
                // Show treatment step
                showStep('treatment-section');
            }
            
            function displaySelectedCustomer(customer) {
                const customerDetails = $('#customer-details');
                customerDetails.html(
                    '<div class="col-md-6">' +
                        '<p><strong>Name:</strong> ' + customer.name + '</p>' +
                        '<p><strong>Email:</strong> ' + customer.email + '</p>' +
                    '</div>' +
                    '<div class="col-md-6">' +
                        '<p><strong>Phone:</strong> ' + (customer.phoneNumber || 'Not provided') + '</p>' +
                        '<p><strong>Past Appointments:</strong> ' + (customer.appointmentCount || 0) + '</p>' +
                    '</div>'
                );
                
                $('#customer-info-display').show();
            }
            
            function clearCustomerSearch() {
                $('#customer_search').val('').focus();
                $('#customer_results').hide();
                
                // Clear any selected customer
                window.selectedCustomerData = null;
                $('#selected_customer_id').val('');
                $('#customer-info-display').hide();
                
                // Reset to customer selection step
                showStep('customer-section');
            }
            
            // Make clearCustomerSearch available globally for onclick
            window.clearCustomerSearch = clearCustomerSearch;
            
            // Generate time slots for appointment booking
            function generateTimeSlots() {
                const timeSlots = [];
                const startHour = 9; // 9 AM
                const endHour = 17; // 5 PM
                const slotDuration = 30; // 30 minutes
                
                for (let hour = startHour; hour < endHour; hour++) {
                    for (let minute = 0; minute < 60; minute += slotDuration) {
                        const timeString = String(hour).padStart(2, '0') + ':' + String(minute).padStart(2, '0');
                        const displayTime = formatTime12Hour(hour, minute);
                        timeSlots.push({
                            value: timeString,
                            display: displayTime
                        });
                    }
                }
                
                return timeSlots;
            }
            
            // Format time to 12-hour format
            function formatTime12Hour(hour, minute) {
                const period = hour >= 12 ? 'PM' : 'AM';
                const displayHour = hour > 12 ? hour - 12 : (hour === 0 ? 12 : hour);
                return displayHour + ':' + String(minute).padStart(2, '0') + ' ' + period;
            }
            
            // Initialize date input restrictions
            function initializeDateRestrictions() {
                const dateInput = document.getElementById('appointment_date');
                const now = new Date();
                const currentHour = now.getHours();
                
                let minDate = new Date();
                if (currentHour >= 17) {
                    minDate.setDate(minDate.getDate() + 1);
                }
                
                const maxDate = new Date();
                maxDate.setDate(maxDate.getDate() + 6);
                
                dateInput.min = formatDateForInput(minDate);
                dateInput.max = formatDateForInput(maxDate);
                
                dateInput.addEventListener('change', function() {
                    validateSelectedDate(this.value);
                });
            }
            
            function formatDateForInput(date) {
                return date.getFullYear() + '-' + 
                       String(date.getMonth() + 1).padStart(2, '0') + '-' + 
                       String(date.getDate()).padStart(2, '0');
            }
            
            function validateSelectedDate(dateValue) {
                if (!dateValue) return false;
                
                const selectedDate = new Date(dateValue + 'T00:00:00');
                const dayOfWeek = selectedDate.getDay();
                const now = new Date();
                const currentHour = now.getHours();
                const today = new Date();
                today.setHours(0, 0, 0, 0);
                selectedDate.setHours(0, 0, 0, 0);
                
                if (dayOfWeek === 0 || dayOfWeek === 6) {
                    alert('Appointments are only available on weekdays (Monday to Friday). Please select a weekday within the booking range.');
                    document.getElementById('appointment_date').value = '';
                    return false;
                }
                
                if (selectedDate.getTime() === today.getTime() && currentHour >= 17) {
                    alert('Appointments for today cannot be booked after 5:00 PM. Please select a future weekday.');
                    document.getElementById('appointment_date').value = '';
                    return false;
                }
                
                if (selectedDate.getTime() < today.getTime()) {
                    alert('Cannot select a past date. Please select a current or future weekday.');
                    document.getElementById('appointment_date').value = '';
                    return false;
                }
                
                return true;
            }
            
            // Enhanced step navigation
            function showStep(sectionId) {
                document.querySelectorAll('.form-section').forEach(section => {
                    section.classList.add('hidden');
                });
                
                document.getElementById(sectionId).classList.remove('hidden');
                updateStepIndicators(sectionId);
            }
            
            function updateStepIndicators(currentSection) {
                const steps = document.querySelectorAll('.step');
                steps.forEach(step => {
                    step.classList.remove('active', 'completed');
                });
                
                let stepNumber;
                switch(currentSection) {
                    case 'customer-section': stepNumber = 0; break;
                    case 'treatment-section': stepNumber = 1; break;
                    case 'date-section': stepNumber = 2; break;
                    case 'doctor-section': stepNumber = 3; break;
                    case 'message-section': stepNumber = 4; break;
                }
                
                for (let i = 0; i < stepNumber; i++) {
                    steps[i].classList.add('completed');
                }
                steps[stepNumber].classList.add('active');
            }
            
            function isStepAccessible(stepNumber) {
                switch(stepNumber) {
                    case 0: return true;
                    case 1: return document.getElementById('selected_customer_id').value !== '';
                    case 2: return document.getElementById('selected_customer_id').value !== '' && 
                                   document.getElementById('treatment').value !== '';
                    case 3: return document.getElementById('selected_customer_id').value !== '' && 
                                   document.getElementById('treatment').value !== '' && 
                                   document.getElementById('appointment_date').value !== '';
                    case 4: return document.getElementById('selected_customer_id').value !== '' && 
                                   document.getElementById('treatment').value !== '' && 
                                   document.getElementById('appointment_date').value !== '' &&
                                   document.getElementById('selected_doctor_id').value !== '' &&
                                   document.getElementById('selected_time_slot').value !== '';
                    default: return false;
                }
            }
            
            function initializeStepNavigation() {
                const steps = document.querySelectorAll('.step.clickable');
                
                steps.forEach(function(step, index) {
                    step.addEventListener('click', function() {
                        const stepNumber = index;
                        const targetSection = this.getAttribute('data-section');
                        
                        if (isStepAccessible(stepNumber)) {
                            showStep(targetSection);
                            
                            if (targetSection === 'doctor-section' && document.getElementById('appointment_date').value) {
                                const treatmentId = document.getElementById('treatment').value;
                                generateDoctorCards(document.getElementById('appointment_date').value, treatmentId);
                            }
                        } else {
                            let message = '';
                            let redirectStep = 'customer-section'; // Default redirect to customer section
                            
                            switch(stepNumber) {
                                case 1: 
                                    message = 'Please select a customer first.';
                                    redirectStep = 'customer-section';
                                    break;
                                case 2: 
                                    message = 'Please select a customer and treatment first.';
                                    redirectStep = document.getElementById('selected_customer_id').value ? 'treatment-section' : 'customer-section';
                                    break;
                                case 3: 
                                    message = 'Please select customer, treatment and date first.';
                                    if (!document.getElementById('selected_customer_id').value) {
                                        redirectStep = 'customer-section';
                                    } else if (!document.getElementById('treatment').value) {
                                        redirectStep = 'treatment-section';
                                    } else {
                                        redirectStep = 'date-section';
                                    }
                                    break;
                                case 4: 
                                    message = 'Please complete the previous steps first.';
                                    if (!document.getElementById('selected_customer_id').value) {
                                        redirectStep = 'customer-section';
                                    } else if (!document.getElementById('treatment').value) {
                                        redirectStep = 'treatment-section';
                                    } else if (!document.getElementById('appointment_date').value) {
                                        redirectStep = 'date-section';
                                    } else {
                                        redirectStep = 'doctor-section';
                                    }
                                    break;
                            }
                            
                            alert(message);
                            // Redirect to appropriate step after error
                            showStep(redirectStep);
                        }
                    });
                });
            }
            
            // Treatment selection handler - validate customer selection first
            document.getElementById('treatment').addEventListener('change', function() {
                if (this.value) {
                    // Check if customer is selected before proceeding
                    if (document.getElementById('selected_customer_id').value) {
                        showStep('date-section');
                    } else {
                        alert('Please select a customer first.');
                        this.value = ''; // Reset treatment selection
                        showStep('customer-section');
                    }
                }
            });
            
            // Date selection handler
            document.getElementById('appointment_date').addEventListener('change', function() {
                if (this.value && validateSelectedDate(this.value)) {
                    const treatmentId = document.getElementById('treatment').value;
                    generateDoctorCards(this.value, treatmentId);
                    showStep('doctor-section');
                }
            });
            
            // Load doctor time slots
            function generateDoctorCards(selectedDate, treatmentId) {
                // Show loading message
                $('#doctor-cards-container').html('<div class="text-center"><i class="fa fa-spinner fa-spin"></i> Loading available doctors and time slots...</div>');
                
                $.ajax({
                    url: '<%= request.getContextPath() %>/AppointmentServlet',
                    method: 'GET',
                    data: {
                        action: 'getAvailableSlots',
                        treatment_id: treatmentId,
                        selected_date: selectedDate
                    },
                    success: function(data) {
                        displayDoctorCards(data.doctors);
                    },
                    error: function(xhr, status, error) {
                        console.error('Error loading doctor time slots:', error);
                        $('#doctor-cards-container').html('<div class="alert alert-danger"><i class="fa fa-exclamation-circle"></i> Unable to load doctor availability. Please try again or refresh the page.</div>');
                    }
                });
            }
            
            function displayDoctorCards(doctors) {
                const container = $('#doctor-cards-container');
                container.empty();
                
                if (doctors && doctors.length > 0) {
                    doctors.forEach(function(doctor) {
                        const doctorCard = $('<div class="doctor-card">');
                        const doctorInfo = $('<div class="doctor-info">');
                        doctorInfo.append('<h5>Dr. ' + doctor.name + '</h5>');
                        doctorInfo.append('<div class="specialization">' + doctor.specialization + '</div>');
                        
                        const timeSlotsGrid = $('<div class="time-slots-grid">');
                        doctor.timeSlots.forEach(function(slot) {
                            const btnClass = slot.available ? 'btn-outline-primary' : 'btn-secondary';
                            const disabled = slot.available ? '' : 'disabled';
                            
                            const slotBtn = $('<button type="button" class="btn ' + btnClass + ' time-slot-btn" ' + disabled + '>')
                                .text(slot.display)
                                .attr('data-doctor-id', doctor.id)
                                .attr('data-time', slot.time)
                                .attr('data-display-time', slot.display)
                                .click(function() {
                                    if (slot.available) {
                                        selectTimeSlot($(this));
                                    }
                                });
                            timeSlotsGrid.append(slotBtn);
                        });
                        
                        doctorCard.append(doctorInfo);
                        doctorCard.append(timeSlotsGrid);
                        container.append(doctorCard);
                    });
                } else {
                    container.append('<div class="alert alert-warning">No available time slots for the selected date.</div>');
                }
            }
            
            function selectTimeSlot(btn) {
                $('.time-slot-btn').removeClass('btn-primary').addClass('btn-outline-primary');
                $('.doctor-card').removeClass('selected');
                
                btn.removeClass('btn-outline-primary').addClass('btn-primary');
                btn.closest('.doctor-card').addClass('selected');
                
                $('#selected_doctor_id').val(btn.data('doctor-id'));
                $('#selected_time_slot').val(btn.data('time'));
                
                showStep('message-section');
            }
            
            // Submit button handler
            document.getElementById('submit-appointment').addEventListener('click', function() {
                if (validateAppointmentForm()) {
                    showConfirmationModal();
                }
            });
            
            function validateAppointmentForm() {
                const customerId = document.getElementById('selected_customer_id').value;
                const treatment = document.getElementById('treatment').value;
                const date = document.getElementById('appointment_date').value;
                const doctorId = document.getElementById('selected_doctor_id').value;
                const timeSlot = document.getElementById('selected_time_slot').value;
                
                if (!customerId) {
                    alert('Please select a customer.');
                    return false;
                }
                
                if (!treatment) {
                    alert('Please select a treatment.');
                    return false;
                }
                
                if (!date) {
                    alert('Please select an appointment date.');
                    return false;
                }
                
                if (!validateSelectedDate(date)) {
                    return false;
                }
                
                if (!doctorId || !timeSlot) {
                    alert('Please select a doctor and time slot.');
                    return false;
                }
                
                return true;
            }
            
            function showConfirmationModal() {
                const treatment = document.getElementById('treatment');
                const date = document.getElementById('appointment_date').value;
                const doctorId = document.getElementById('selected_doctor_id').value;
                const timeSlot = document.getElementById('selected_time_slot').value;
                const message = document.getElementById('staff_message').value;

                const selectedDoctor = window.doctorData.find(d => d.id == doctorId);
                const selectedTimeBtn = document.querySelector('.time-slot-btn.selected, .time-slot-btn.btn-primary');
                const timeDisplay = selectedTimeBtn ? selectedTimeBtn.getAttribute('data-display-time') : timeSlot;
                
                const dateObj = new Date(date + 'T00:00:00');
                const dateDisplay = dateObj.toLocaleDateString('en-US', { 
                    weekday: 'long', 
                    year: 'numeric', 
                    month: 'long', 
                    day: 'numeric' 
                });
                
                // Populate customer info in modal
                if (window.selectedCustomerData) {
                    document.getElementById('confirm-customer-name').textContent = window.selectedCustomerData.name;
                    document.getElementById('confirm-customer-email').textContent = window.selectedCustomerData.email;
                    document.getElementById('confirm-customer-phone').textContent = window.selectedCustomerData.phoneNumber || 'Not provided';
                }
                
                // Populate appointment details
                document.getElementById('confirm-treatment').textContent = treatment.options[treatment.selectedIndex].text;
                document.getElementById('confirm-doctor').textContent = 'Dr. ' + selectedDoctor.name;
                document.getElementById('confirm-date').textContent = dateDisplay;
                document.getElementById('confirm-time').textContent = timeDisplay;
                document.getElementById('confirm-message').textContent = message || 'No specific concerns mentioned.';
                
                $('#confirmationModal').modal('show');
            }
            
            // Final confirmation handler
            document.getElementById('final-confirm').addEventListener('click', function() {
                document.getElementById('appointment-form').submit();
            });
            
            // Initialize with pre-selected treatment if available
            if (window.preSelectedTreatment) {
                document.getElementById('treatment').value = window.preSelectedTreatment;
            }
        });
    </script>

</body>
</html>
