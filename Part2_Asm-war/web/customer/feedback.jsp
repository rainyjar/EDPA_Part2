<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="model.*" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%
    // Check if user is logged in
    Customer loggedInCustomer = (Customer) session.getAttribute("customer");
    if (loggedInCustomer == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    // Get appointment ID from parameter
    String appointmentIdParam = request.getParameter("appointment_id");
    if (appointmentIdParam == null || appointmentIdParam.trim().isEmpty()) {
        response.sendRedirect(request.getContextPath() + "/AppointmentServlet?action=history&error=invalid_appointment");
        return;
    }

    int appointmentId;
    try {
        appointmentId = Integer.parseInt(appointmentIdParam);
    } catch (NumberFormatException e) {
        response.sendRedirect(request.getContextPath() + "/AppointmentServlet?action=history&error=invalid_appointment");
        return;
    }

    // Get appointment details from request attributes (set by servlet)
    Appointment appointment = (Appointment) request.getAttribute("appointment");
    Feedback existingFeedback = (Feedback) request.getAttribute("existingFeedback");

    // If appointment data not loaded, redirect back
    if (appointment == null) {
        response.sendRedirect(request.getContextPath() + "/AppointmentServlet?action=history&error=appointment_not_found");
        return;
    }

    // Validate appointment belongs to logged-in customer
    if (appointment.getCustomer() == null
            || appointment.getCustomer().getId() != loggedInCustomer.getId()) {
        response.sendRedirect(request.getContextPath() + "/AppointmentServlet?action=history&error=unauthorized");
        return;
    }

    // Check if appointment is completed
    if (!"completed".equals(appointment.getStatus())) {
        response.sendRedirect(request.getContextPath() + "/AppointmentServlet?action=history&error=not_completed");
        return;
    }

    SimpleDateFormat dateFormatter = new SimpleDateFormat("dd/MM/yyyy");
    SimpleDateFormat timeFormatter = new SimpleDateFormat("HH:mm");
%>

<!DOCTYPE html>
<html lang="en">

    <head>
        <title>Submit Feedback - APU Medical Center</title>
        <%@ include file="/includes/head.jsp" %>
        
        <style>
            .section-header {
                display: flex;
                align-items: center;
                margin-bottom: 20px;
            }
            
            .section-header h4 {
                margin: 0;
                flex: 1;
            }
            
            .rating-label {
                font-weight: bold;
                color: #333;
                margin-top: 10px;
                text-align: center;
            }
            
            .rating-description {
                font-size: 14px;
                color: #666;
                margin-top: 5px;
                min-height: 20px;
                text-align: center;
            }
            
            /* Ensure stars are visible and clickable - override any conflicting styles */
            .star {
                font-size: 2.5em !important;
                color: #ddd !important;
                cursor: pointer !important;
                transition: all 0.2s ease !important;
                user-select: none !important;
                display: inline-block !important;
                line-height: 1 !important;
                margin: 0 3px !important;
                z-index: 10 !important;
                position: relative !important;
            }
            
            .star:hover {
                color: #ffc107 !important;
                text-shadow: 0 0 10px rgba(255, 193, 7, 0.5) !important;
                transform: scale(1.1) !important;
            }
            
            .star.active {
                color: #ffc107 !important;
                text-shadow: 0 0 10px rgba(255, 193, 7, 0.5) !important;
                transform: scale(1.05) !important;
            }
            
            .star-rating {
                display: flex !important;
                align-items: center !important;
                justify-content: center !important;
                gap: 5px !important;
                margin: 10px 0 !important;
                min-height: 60px !important;
            }
            
            .rating-stars {
                display: flex !important;
                justify-content: center !important;
                margin: 20px 0 !important;
            }
        </style>
    </head>

    <body id="top" data-spy="scroll" data-target=".navbar-collapse" data-offset="50">

        <%@ include file="/includes/preloader.jsp" %>
        <%@ include file="/includes/header.jsp" %>
        <%@ include file="/includes/navbar.jsp" %>

        <%        String errorMsg = request.getParameter("error");
            String successMsg = request.getParameter("success");
        %>

        <!-- Error/Success Messages -->
        <% if (errorMsg != null) { %>
        <div class="alert alert-danger alert-dismissible" style="margin: 20px; position: fixed; top: 80px; right: 20px; z-index: 1000; width: 350px;">
            <button type="button" class="close" data-dismiss="alert">&times;</button>
            <strong>Error!</strong> 
            <% if ("invalid_appointment".equals(errorMsg)) { %>
            Invalid appointment ID provided.
            <% } else if ("appointment_not_found".equals(errorMsg)) { %>
            Appointment not found.
            <% } else if ("unauthorized".equals(errorMsg)) { %>
            You are not authorized to provide feedback for this appointment.
            <% } else if ("not_completed".equals(errorMsg)) { %>
            Feedback can only be submitted for completed appointments.
            <% } else if ("feedback_exists".equals(errorMsg)) { %>
            You have already submitted feedback for this appointment.
            <% } else if ("invalid_rating".equals(errorMsg)) { %>
            Please provide a valid rating between 1 and 10.
            <% } else if ("rating_required".equals(errorMsg)) { %>
            Rating is required to submit feedback.
            <% } else if ("invalid_feedback_type".equals(errorMsg)) { %>
            Invalid feedback type specified.
            <% } else if ("no_feedback".equals(errorMsg)) { %>
            Please provide at least a rating to submit feedback.
            <% } else if ("system_error".equals(errorMsg)) { %>
            A system error occurred. Please try again.
            <% } else { %>
            An unexpected error occurred.
            <% } %>
        </div>
        <% } %>

        <% if (successMsg != null) { %>
        <div class="alert alert-success alert-dismissible" style="margin: 20px; position: fixed; top: 80px; right: 20px; z-index: 1000; width: 350px;">
            <button type="button" class="close" data-dismiss="alert">&times;</button>
            <strong>Success!</strong> 
            <% if ("doctor_submitted".equals(successMsg)) { %>
            Your doctor feedback has been submitted successfully!
            <% } else if ("staff_submitted".equals(successMsg)) { %>
            Your counter staff feedback has been submitted successfully!
            <% } else { %>
            Your feedback has been submitted successfully!
            <% } %>
        </div>
        <% }%>

        <!-- FEEDBACK SECTION -->
        <section class="feedback-container">
            <div class="container">
                <div class="row">
                    <div class="col-md-10 col-md-offset-1">

                        <!-- Page Header -->
                        <div class="text-center" style="margin-bottom: 30px;">
                            <h2 style="color: #2c3e50; margin-bottom: 10px;">
                                <i class="fa fa-star"></i> Submit Feedback
                            </h2>
                            <p style="color: #666; font-size: 16px;">
                                Share your experience about your recent appointment
                            </p>
                        </div>

                        <div class="feedback-form-wrapper">

                            <!-- Appointment Summary -->
                            <div class="appointment-summary">
                                <h4><i class="fa fa-calendar-check-o"></i> Appointment Details</h4>
                                <div class="appointment-details">
                                    <div class="detail-item">
                                        <i class="fa fa-hashtag"></i>
                                        <span><strong>ID:</strong> #<%= appointment.getId()%></span>
                                    </div>
                                    <div class="detail-item">
                                        <i class="fa fa-calendar"></i>
                                        <span><strong>Date:</strong> <%= dateFormatter.format(appointment.getAppointmentDate())%></span>
                                    </div>
                                    <div class="detail-item">
                                        <i class="fa fa-clock-o"></i>
                                        <span><strong>Time:</strong> <%= appointment.getAppointmentTime() != null ? appointment.getAppointmentTime().toString() : "N/A"%></span>
                                    </div>
                                    <div class="detail-item">
                                        <i class="fa fa-stethoscope"></i>
                                        <span><strong>Treatment:</strong> <%= appointment.getTreatment() != null ? appointment.getTreatment().getName() : "N/A"%></span>
                                    </div>
                                    <div class="detail-item">
                                        <i class="fa fa-user-md"></i>
                                        <span><strong>Doctor:</strong> <%= appointment.getDoctor() != null ? appointment.getDoctor().getName() : "N/A"%></span>
                                    </div>
                                    <div class="detail-item">
                                        <i class="fa fa-user"></i>
                                        <span><strong>Counter Staff:</strong> <%= appointment.getCounterStaff() != null ? appointment.getCounterStaff().getName() : "N/A"%></span>
                                    </div>
                                </div>
                            </div>

                            <!-- Feedback Form -->
                            <!-- Doctor Feedback Section -->
                            <% if (appointment.getDoctor() != null) {%>
                            <% boolean doctorFeedbackSubmitted = (existingFeedback != null && existingFeedback.getDocRating() > 0); %>
                            
                            <% if (doctorFeedbackSubmitted) { %>
                            <!-- View-only doctor feedback -->
                            <div class="feedback-section" id="doctor-feedback-view">
                                <div class="section-header">
                                    <i class="fa fa-user-md"></i>
                                    <h4>Doctor Feedback: <%= appointment.getDoctor().getName()%></h4>
                                </div>

                                <div class="rating-container">
                                    <label class="form-label">Your rating for the doctor's service:</label>
                                    <div class="rating-stars">
                                        <div class="star-rating readonly" data-target="doctor-readonly">
                                            <% 
                                            double docRating = existingFeedback.getDocRating();
                                            int starCount = (int) Math.round(docRating);
                                            for (int i = 1; i <= 10; i++) {%>
                                            <span class="star <%= i <= starCount ? "active" : "" %>">★</span>
                                            <% } %>
                                        </div>
                                    </div>
                                    <div class="rating-label">
                                        Rating: <%= String.format("%.1f", docRating) %>/10
                                    </div>
                                </div>

                                <% if (existingFeedback.getCustDocComment() != null && !existingFeedback.getCustDocComment().trim().isEmpty()) { %>
                                <div class="comment-section">
                                    <label class="form-label">Your comment about the doctor:</label>
                                    <div class="submitted-comment"><%= existingFeedback.getCustDocComment() %></div>
                                </div>
                                <% } %>
                            </div>
                            <% } else { %>
                            <!-- Editable doctor feedback form -->
                            <form id="doctor-feedback-form" method="post" action="FeedbackServlet">
                                <input type="hidden" name="action" value="submit_feedback">
                                <input type="hidden" name="appointment_id" value="<%= appointment.getId()%>">
                                <input type="hidden" name="feedback_type" value="doctor">

                                <div class="feedback-section" id="doctor-feedback">
                                    <div class="section-header">
                                        <i class="fa fa-user-md"></i>
                                        <h4>Rate Your Doctor: <%= appointment.getDoctor().getName()%></h4>
                                    </div>

                                    <div class="rating-container">
                                        <label class="form-label">How would you rate your doctor's service? *</label>
                                        <div class="rating-stars">
                                            <div class="star-rating" data-target="doctor">
                                                <% for (int i = 1; i <= 10; i++) {%>
                                                <span class="star" data-rating="<%= i%>">★</span>
                                                <% } %>
                                            </div>
                                        </div>
                                        <div class="rating-label" id="doctor-rating-label">Select a rating (Required)</div>
                                        <div class="rating-description" id="doctor-rating-desc"></div>
                                        <input type="hidden" name="doctor_rating" id="doctor-rating-input" required>
                                        <div class="validation-message" id="doctor-rating-error">Please provide a rating for the doctor</div>
                                    </div>

                                    <div class="comment-section">
                                        <label for="doctor-comment" class="form-label">Comments about your doctor (Optional):</label>
                                        <textarea id="doctor-comment" name="doctor_comment" class="form-control" rows="4" 
                                                  placeholder="Share your experience with the doctor's consultation, professionalism, diagnosis, etc."></textarea>
                                    </div>

                                    <!-- Submit Section -->
                                    <div class="text-center" style="margin-top: 40px;">
                                        <button type="submit" id="submit-doc-feedback" class="submit-feedback-btn">
                                            <i class="fa fa-paper-plane"></i> Submit Doctor Feedback
                                        </button>
                                    </div>     
                                </div>
                            </form>
                            <% } %>
                            <% } %>

                            <!-- Staff Feedback Section -->
                            <% if (appointment.getCounterStaff() != null) {%>
                            <% boolean staffFeedbackSubmitted = (existingFeedback != null && existingFeedback.getStaffRating() > 0); %>
                            
                            <% if (staffFeedbackSubmitted) { %>
                            <!-- View-only staff feedback -->
                            <div class="feedback-section" id="staff-feedback-view">
                                <div class="section-header">
                                    <i class="fa fa-users"></i>
                                    <h4>Staff Feedback: <%= appointment.getCounterStaff().getName()%></h4>
                                </div>

                                <div class="rating-container">
                                    <label class="form-label">Your rating for the staff's service:</label>
                                    <div class="rating-stars">
                                        <div class="star-rating readonly" data-target="staff-readonly">
                                            <% 
                                            double staffRating = existingFeedback.getStaffRating();
                                            int starCount = (int) Math.round(staffRating);
                                            for (int i = 1; i <= 10; i++) {%>
                                            <span class="star <%= i <= starCount ? "active" : "" %>">★</span>
                                            <% } %>
                                        </div>
                                    </div>
                                    <div class="rating-label">
                                        Rating: <%= String.format("%.1f", staffRating) %>/10
                                    </div>
                                </div>

                                <% if (existingFeedback.getCustStaffComment() != null && !existingFeedback.getCustStaffComment().trim().isEmpty()) { %>
                                <div class="comment-section">
                                    <label class="form-label">Your comment about the staff:</label>
                                    <div class="submitted-comment"><%= existingFeedback.getCustStaffComment() %></div>
                                </div>
                                <% } %>
                            </div>
                            <% } else { %>
                            <!-- Editable staff feedback form -->
                            <form id="staff-feedback-form" method="post" action="FeedbackServlet" style="margin-top: 30px;">
                                <input type="hidden" name="action" value="submit_feedback">
                                <input type="hidden" name="appointment_id" value="<%= appointment.getId()%>">
                                <input type="hidden" name="feedback_type" value="staff">

                                <div class="feedback-section" id="staff-feedback">
                                    <div class="section-header">
                                        <i class="fa fa-users"></i>
                                        <h4>Rate Our Counter Staff: <%= appointment.getCounterStaff().getName()%></h4>
                                    </div>

                                    <div class="rating-container">
                                        <label class="form-label">How would you rate our staff's service? *</label>
                                        <div class="rating-stars">
                                            <div class="star-rating" data-target="staff">
                                                <% for (int i = 1; i <= 10; i++) {%>
                                                <span class="star" data-rating="<%= i%>">★</span>
                                                <% } %>
                                            </div>
                                        </div>
                                        <div class="rating-label" id="staff-rating-label">Select a rating (Required)</div>
                                        <div class="rating-description" id="staff-rating-desc"></div>
                                        <input type="hidden" name="staff_rating" id="staff-rating-input" required>
                                        <div class="validation-message" id="staff-rating-error">Please provide a rating for the staff</div>
                                    </div>

                                    <div class="comment-section">
                                        <label for="staff-comment" class="form-label">Comments about our staff (Optional):</label>
                                        <textarea id="staff-comment" name="staff_comment" class="form-control" rows="4" 
                                                  placeholder="Share your experience with the staff's courtesy, efficiency, appointment handling, etc."></textarea>
                                    </div>

                                    <!-- Submit Section -->
                                    <div class="text-center" style="margin-top: 40px;">
                                        <button type="submit" id="submit-staff-feedback" class="submit-feedback-btn">
                                            <i class="fa fa-paper-plane"></i> Submit Staff Feedback
                                        </button>
                                    </div>     
                                </div>
                            </form>
                            <% } %>
                            <% } %>

                            <div class="text-center" style="margin-top: 40px;">
                                <a href="<%= request.getContextPath()%>/AppointmentServlet?action=history" class="btn btn-secondary">
                                    <i class="fa fa-arrow-left"></i> Back to Appointment History
                                </a>
                            </div>
                        </div>  
                    </div>
                </div>
            </div>
        </section>

        <%@ include file="/includes/footer.jsp" %>
        <%@ include file="/includes/scripts.jsp" %>

        <script>
            // Simple and robust star rating implementation
            window.addEventListener('load', function () {
                
                // Rating descriptions
                const ratingDescriptions = {
                    1: "Very Poor - Service was unacceptable",
                    2: "Poor - Service fell short of expectations", 
                    3: "Below Average - Service had significant issues",
                    4: "Below Average - Service was lacking",
                    5: "Average - Service met basic expectations",
                    6: "Above Average - Service was satisfactory",
                    7: "Good - Service was good with minor issues",
                    8: "Very Good - Service exceeded expectations",
                    9: "Excellent - Outstanding service quality",
                    10: "Perfect - Exceptional service, could not be better"
                };

                // Initialize doctor rating if form exists
                const doctorStars = document.querySelectorAll('.star-rating[data-target="doctor"] .star');
                const doctorInput = document.getElementById('doctor-rating-input');
                const doctorLabel = document.getElementById('doctor-rating-label');
                const doctorDesc = document.getElementById('doctor-rating-desc');
                
                if (doctorStars.length > 0 && doctorInput) {
                    console.log('Initializing doctor rating with', doctorStars.length, 'stars');
                    setupStarRating(doctorStars, doctorInput, doctorLabel, doctorDesc, 'doctor');
                }

                // Initialize staff rating if form exists
                const staffStars = document.querySelectorAll('.star-rating[data-target="staff"] .star');
                const staffInput = document.getElementById('staff-rating-input');
                const staffLabel = document.getElementById('staff-rating-label');
                const staffDesc = document.getElementById('staff-rating-desc');
                
                if (staffStars.length > 0 && staffInput) {
                    console.log('Initializing staff rating with', staffStars.length, 'stars');
                    setupStarRating(staffStars, staffInput, staffLabel, staffDesc, 'staff');
                }

                function setupStarRating(stars, input, label, desc, type) {
                    let currentRating = 0;
                    
                    stars.forEach(function(star) {
                        const rating = parseInt(star.getAttribute('data-rating'));
                        
                        // Click handler
                        star.addEventListener('click', function() {
                            console.log('Star clicked:', rating, 'for', type);
                            currentRating = rating;
                            input.value = rating.toFixed(1);
                            
                            // Update visual state
                            updateStarDisplay(stars, rating);
                            
                            // Update labels
                            if (label) label.textContent = 'Rating: ' + rating.toFixed(1) + '/10';
                            if (desc) desc.textContent = ratingDescriptions[rating];
                            
                            // Hide error message
                            const errorMsg = document.getElementById(type + '-rating-error');
                            if (errorMsg) errorMsg.style.display = 'none';
                            
                            // Enable submit button
                            enableSubmitButton(type);
                        });
                        
                        // Hover handler
                        star.addEventListener('mouseover', function() {
                            updateStarDisplay(stars, rating);
                            if (label) label.textContent = 'Rating: ' + rating.toFixed(1) + '/10';
                            if (desc) desc.textContent = ratingDescriptions[rating];
                        });
                    });
                    
                    // Mouse leave handler for container
                    const container = stars[0].parentElement;
                    container.addEventListener('mouseleave', function() {
                        updateStarDisplay(stars, currentRating);
                        if (currentRating > 0) {
                            if (label) label.textContent = 'Rating: ' + currentRating.toFixed(1) + '/10';
                            if (desc) desc.textContent = ratingDescriptions[currentRating];
                        } else {
                            if (label) label.textContent = 'Select a rating (Required)';
                            if (desc) desc.textContent = '';
                        }
                    });
                }

                function updateStarDisplay(stars, rating) {
                    stars.forEach(function(star) {
                        const starValue = parseInt(star.getAttribute('data-rating'));
                        if (starValue <= rating) {
                            star.classList.add('active');
                        } else {
                            star.classList.remove('active');
                        }
                    });
                }
                
                function enableSubmitButton(type) {
                    let submitBtnId;
                    if (type === 'doctor') {
                        submitBtnId = 'submit-doc-feedback';
                    } else if (type === 'staff') {
                        submitBtnId = 'submit-staff-feedback';
                    }
                    
                    const submitBtn = document.getElementById(submitBtnId);
                    if (submitBtn) {
                        submitBtn.disabled = false;
                    }
                }

                // Form submission handlers
                const doctorForm = document.getElementById('doctor-feedback-form');
                if (doctorForm) {
                    doctorForm.addEventListener('submit', function (e) {
                        const doctorRating = document.getElementById('doctor-rating-input');
                        
                        if (!doctorRating.value || parseFloat(doctorRating.value) < 1.0 || parseFloat(doctorRating.value) > 10.0) {
                            e.preventDefault();
                            const errorEl = document.getElementById('doctor-rating-error');
                            if (errorEl) errorEl.style.display = 'block';
                            return false;
                        }

                        // Show loading state
                        const submitBtn = document.getElementById('submit-doc-feedback');
                        if (submitBtn) {
                            submitBtn.innerHTML = '<i class="fa fa-spinner fa-spin"></i> Submitting...';
                            submitBtn.disabled = true;
                        }
                    });
                }

                const staffForm = document.getElementById('staff-feedback-form');
                if (staffForm) {
                    staffForm.addEventListener('submit', function (e) {
                        const staffRating = document.getElementById('staff-rating-input');
                        
                        if (!staffRating.value || parseFloat(staffRating.value) < 1.0 || parseFloat(staffRating.value) > 10.0) {
                            e.preventDefault();
                            const errorEl = document.getElementById('staff-rating-error');
                            if (errorEl) errorEl.style.display = 'block';
                            return false;
                        }

                        // Show loading state
                        const submitBtn = document.getElementById('submit-staff-feedback');
                        if (submitBtn) {
                            submitBtn.innerHTML = '<i class="fa fa-spinner fa-spin"></i> Submitting...';
                            submitBtn.disabled = true;
                        }
                    });
                }

                // Auto-dismiss alerts
                setTimeout(function () {
                    const alerts = document.querySelectorAll('.alert');
                    alerts.forEach(function (alert) {
                        alert.style.display = 'none';
                    });
                }, 5000);
            });
        </script>

        <%@ include file="/includes/scripts.jsp" %>

    </body>

</html>
