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
        response.sendRedirect(request.getContextPath() + "/customer/appointment_history.jsp?error=invalid_appointment");
        return;
    }
    
    int appointmentId;
    try {
        appointmentId = Integer.parseInt(appointmentIdParam);
    } catch (NumberFormatException e) {
        response.sendRedirect(request.getContextPath() + "/customer/appointment_history.jsp?error=invalid_appointment");
        return;
    }
    
    // Get appointment details from request attributes (set by servlet)
    Appointment appointment = (Appointment) request.getAttribute("appointment");
    Boolean feedbackExists = (Boolean) request.getAttribute("feedbackExists");
    
    // If appointment data not loaded, redirect back
    if (appointment == null) {
        response.sendRedirect(request.getContextPath() + "/customer/appointment_history.jsp?error=appointment_not_found");
        return;
    }
    
    // Validate appointment belongs to logged-in customer
    if (appointment.getCustomer() == null || 
        appointment.getCustomer().getId() != loggedInCustomer.getId()) {
        response.sendRedirect(request.getContextPath() + "/customer/appointment_history.jsp?error=unauthorized");
        return;
    }
    
    // Check if appointment is completed
    if (!"completed".equals(appointment.getStatus())) {
        response.sendRedirect(request.getContextPath() + "/customer/appointment_history.jsp?error=not_completed");
        return;
    }
    
    // Check if feedback already exists
    if (feedbackExists != null && feedbackExists) {
        response.sendRedirect(request.getContextPath() + "/customer/appointment_history.jsp?error=feedback_exists");
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
        .feedback-container {
            background: #f8f9fa;
            padding: 60px 0;
            min-height: 100vh;
        }
        
        .feedback-form-wrapper {
            background: white;
            border-radius: 10px;
            box-shadow: 0 5px 20px rgba(0,0,0,0.1);
            padding: 40px;
            margin-top: 20px;
        }
        
        .appointment-summary {
            background: #e3f2fd;
            border-left: 4px solid #2196f3;
            padding: 20px;
            margin-bottom: 30px;
            border-radius: 5px;
        }
        
        .appointment-summary h4 {
            color: #1976d2;
            margin-bottom: 15px;
        }
        
        .appointment-details {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 15px;
        }
        
        .detail-item {
            display: flex;
            align-items: center;
        }
        
        .detail-item i {
            color: #2196f3;
            margin-right: 10px;
            width: 20px;
        }
        
        .feedback-section {
            margin-bottom: 30px;
            padding: 25px;
            border: 1px solid #e0e0e0;
            border-radius: 8px;
            background: #fafafa;
        }
        
        .feedback-section.active {
            border-color: #2196f3;
            background: #f3f8ff;
        }
        
        .section-header {
            display: flex;
            align-items: center;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 2px solid #2196f3;
        }
        
        .section-header i {
            font-size: 24px;
            color: #2196f3;
            margin-right: 15px;
        }
        
        .section-header h4 {
            margin: 0;
            color: #333;
        }
        
        .rating-container {
            margin: 20px 0;
        }
        
        .rating-stars {
            display: flex;
            justify-content: center;
            margin: 20px 0;
            gap: 10px;
        }
        
        .star-rating {
            display: flex;
            align-items: center;
            gap: 5px;
        }
        
        .star {
            font-size: 2.5em;
            color: #ddd;
            cursor: pointer;
            transition: all 0.2s ease;
            user-select: none;
        }
        
        .star:hover,
        .star.active {
            color: #ffc107;
            text-shadow: 0 0 10px rgba(255, 193, 7, 0.5);
            transform: scale(1.1);
        }
        
        .rating-label {
            text-align: center;
            margin-top: 10px;
            font-weight: bold;
            color: #666;
        }
        
        .rating-description {
            text-align: center;
            margin-top: 5px;
            font-size: 14px;
            color: #888;
            min-height: 20px;
        }
        
        .comment-section {
            margin-top: 20px;
        }
        
        .form-control {
            border: 2px solid #e0e0e0;
            border-radius: 8px;
            padding: 12px 15px;
            font-size: 14px;
            transition: border-color 0.3s ease;
        }
        
        .form-control:focus {
            border-color: #2196f3;
            box-shadow: 0 0 0 0.2rem rgba(33, 150, 243, 0.25);
        }
        
        .submit-feedback-btn {
            background: linear-gradient(135deg, #4caf50, #45a049);
            border: none;
            color: white;
            padding: 15px 40px;
            font-size: 16px;
            font-weight: bold;
            border-radius: 8px;
            cursor: pointer;
            transition: all 0.3s ease;
            text-transform: uppercase;
            letter-spacing: 1px;
            box-shadow: 0 4px 15px rgba(76, 175, 80, 0.3);
        }
        
        .submit-feedback-btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 20px rgba(76, 175, 80, 0.4);
        }
        
        .submit-feedback-btn:disabled {
            background: #ccc;
            cursor: not-allowed;
            transform: none;
            box-shadow: none;
        }
        
        .validation-message {
            color: #f44336;
            font-size: 12px;
            margin-top: 5px;
            display: none;
        }
        
        .success-message {
            background: #d4edda;
            color: #155724;
            border: 1px solid #c3e6cb;
            border-radius: 5px;
            padding: 15px;
            margin-bottom: 20px;
        }
        
        .error-message {
            background: #f8d7da;
            color: #721c24;
            border: 1px solid #f5c6cb;
            border-radius: 5px;
            padding: 15px;
            margin-bottom: 20px;
        }
        
        @media (max-width: 768px) {
            .feedback-form-wrapper {
                padding: 20px;
            }
            
            .appointment-details {
                grid-template-columns: 1fr;
            }
            
            .star {
                font-size: 2em;
            }
        }
    </style>
</head>

<body id="top" data-spy="scroll" data-target=".navbar-collapse" data-offset="50">

    <%@ include file="/includes/preloader.jsp" %>
    <%@ include file="/includes/header.jsp" %>
    <%@ include file="/includes/navbar.jsp" %>

    <%
    String errorMsg = request.getParameter("error");
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
        <% } else if ("system_error".equals(errorMsg)) { %>
            A system error occurred. Please try again.
        <% } else { %>
            An unexpected error occurred.
        <% } %>
    </div>
    <% } %>

    <% if (successMsg != null && "feedback_submitted".equals(successMsg)) { %>
    <div class="alert alert-success alert-dismissible" style="margin: 20px; position: fixed; top: 80px; right: 20px; z-index: 1000; width: 350px;">
        <button type="button" class="close" data-dismiss="alert">&times;</button>
        <strong>Success!</strong> Your feedback has been submitted successfully!
    </div>
    <% } %>

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
                                    <span><strong>ID:</strong> #<%= appointment.getId() %></span>
                                </div>
                                <div class="detail-item">
                                    <i class="fa fa-calendar"></i>
                                    <span><strong>Date:</strong> <%= dateFormatter.format(appointment.getAppointmentDate()) %></span>
                                </div>
                                <div class="detail-item">
                                    <i class="fa fa-clock-o"></i>
                                    <span><strong>Time:</strong> <%= appointment.getAppointmentTime() != null ? appointment.getAppointmentTime().toString() : "N/A" %></span>
                                </div>
                                <div class="detail-item">
                                    <i class="fa fa-stethoscope"></i>
                                    <span><strong>Treatment:</strong> <%= appointment.getTreatment() != null ? appointment.getTreatment().getName() : "N/A" %></span>
                                </div>
                                <div class="detail-item">
                                    <i class="fa fa-user-md"></i>
                                    <span><strong>Doctor:</strong> <%= appointment.getDoctor() != null ? appointment.getDoctor().getName() : "N/A" %></span>
                                </div>
                                <div class="detail-item">
                                    <i class="fa fa-user"></i>
                                    <span><strong>Counter Staff:</strong> <%= appointment.getCounterStaff() != null ? appointment.getCounterStaff().getName() : "N/A" %></span>
                                </div>
                            </div>
                        </div>

                        <!-- Feedback Form -->
                        <form id="feedback-form" method="post" action="ScheduleServlet">
                            <input type="hidden" name="action" value="submit_feedback">
                            <input type="hidden" name="appointment_id" value="<%= appointment.getId() %>">
                            
                            <!-- Doctor Feedback Section -->
                            <% if (appointment.getDoctor() != null) { %>
                            <div class="feedback-section" id="doctor-feedback">
                                <div class="section-header">
                                    <i class="fa fa-user-md"></i>
                                    <h4>Rate Your Doctor: <%= appointment.getDoctor().getName() %></h4>
                                </div>
                                
                                <div class="rating-container">
                                    <label class="form-label">How would you rate your doctor's service?</label>
                                    <div class="rating-stars">
                                        <div class="star-rating" data-target="doctor">
                                            <% for (int i = 1; i <= 10; i++) { %>
                                                <span class="star" data-rating="<%= i %>">★</span>
                                            <% } %>
                                        </div>
                                    </div>
                                    <div class="rating-label" id="doctor-rating-label">Select a rating</div>
                                    <div class="rating-description" id="doctor-rating-desc"></div>
                                    <input type="hidden" name="doctor_rating" id="doctor-rating-input" required>
                                    <div class="validation-message" id="doctor-rating-error">Please provide a rating for the doctor</div>
                                </div>
                                
                                <div class="comment-section">
                                    <label for="doctor-comment" class="form-label">Comments about your doctor (Optional):</label>
                                    <textarea id="doctor-comment" name="doctor_comment" class="form-control" rows="4" 
                                              placeholder="Share your experience with the doctor's consultation, professionalism, diagnosis, etc."></textarea>
                                </div>
                            </div>
                            <% } %>
                            
                            <!-- Counter Staff Feedback Section -->
                            <% if (appointment.getCounterStaff() != null) { %>
                            <div class="feedback-section" id="staff-feedback">
                                <div class="section-header">
                                    <i class="fa fa-user"></i>
                                    <h4>Rate Counter Staff: <%= appointment.getCounterStaff().getName() %></h4>
                                </div>
                                
                                <div class="rating-container">
                                    <label class="form-label">How would you rate the counter staff's service?</label>
                                    <div class="rating-stars">
                                        <div class="star-rating" data-target="staff">
                                            <% for (int i = 1; i <= 10; i++) { %>
                                                <span class="star" data-rating="<%= i %>">★</span>
                                            <% } %>
                                        </div>
                                    </div>
                                    <div class="rating-label" id="staff-rating-label">Select a rating</div>
                                    <div class="rating-description" id="staff-rating-desc"></div>
                                    <input type="hidden" name="staff_rating" id="staff-rating-input" required>
                                    <div class="validation-message" id="staff-rating-error">Please provide a rating for the counter staff</div>
                                </div>
                                
                                <div class="comment-section">
                                    <label for="staff-comment" class="form-label">Comments about counter staff (Optional):</label>
                                    <textarea id="staff-comment" name="staff_comment" class="form-control" rows="4" 
                                              placeholder="Share your experience with the staff's helpfulness, efficiency, friendliness, etc."></textarea>
                                </div>
                            </div>
                            <% } %>
                            
                            <!-- Submit Section -->
                            <div class="text-center" style="margin-top: 40px;">
                                <button type="submit" id="submit-feedback" class="submit-feedback-btn" disabled>
                                    <i class="fa fa-paper-plane"></i> Submit Feedback
                                </button>
                                <br><br>
                                <a href="appointment_history.jsp" class="btn btn-secondary">
                                    <i class="fa fa-arrow-left"></i> Back to Appointment History
                                </a>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <%@ include file="/includes/footer.jsp" %>
    <%@ include file="/includes/scripts.jsp" %>
    
    <script>
        document.addEventListener('DOMContentLoaded', function() {
            
            // Rating system
            const ratingDescriptions = {
                1: "Very Poor - Extremely unsatisfied",
                2: "Poor - Very unsatisfied", 
                3: "Below Average - Unsatisfied",
                4: "Below Average - Somewhat unsatisfied",
                5: "Average - Neither satisfied nor unsatisfied",
                6: "Above Average - Somewhat satisfied",
                7: "Good - Satisfied",
                8: "Very Good - Very satisfied",
                9: "Excellent - Extremely satisfied",
                10: "Outstanding - Exceptional service"
            };
            
            // Initialize star ratings
            document.querySelectorAll('.star-rating').forEach(function(ratingContainer) {
                const target = ratingContainer.getAttribute('data-target');
                const stars = ratingContainer.querySelectorAll('.star');
                const input = document.getElementById(`${target}-rating-input`);
                const label = document.getElementById(`${target}-rating-label`);
                const desc = document.getElementById(`${target}-rating-desc`);
                
                stars.forEach(function(star, index) {
                    star.addEventListener('click', function() {
                        const rating = parseInt(this.getAttribute('data-rating'));
                        
                        // Update hidden input
                        input.value = rating;
                        
                        // Update visual feedback
                        updateStars(stars, rating);
                        label.textContent = `Rating: ${rating}/10`;
                        desc.textContent = ratingDescriptions[rating];
                        
                        // Hide validation error
                        document.getElementById(`${target}-rating-error`).style.display = 'none';
                        
                        // Check if form is valid
                        validateForm();
                    });
                    
                    star.addEventListener('mouseover', function() {
                        const rating = parseInt(this.getAttribute('data-rating'));
                        updateStars(stars, rating);
                        label.textContent = `Rating: ${rating}/10`;
                        desc.textContent = ratingDescriptions[rating];
                    });
                });
                
                ratingContainer.addEventListener('mouseleave', function() {
                    const currentRating = parseInt(input.value) || 0;
                    updateStars(stars, currentRating);
                    if (currentRating > 0) {
                        label.textContent = `Rating: ${currentRating}/10`;
                        desc.textContent = ratingDescriptions[currentRating];
                    } else {
                        label.textContent = 'Select a rating';
                        desc.textContent = '';
                    }
                });
            });
            
            function updateStars(stars, rating) {
                stars.forEach(function(star, index) {
                    if (index < rating) {
                        star.classList.add('active');
                    } else {
                        star.classList.remove('active');
                    }
                });
            }
            
            // Form validation
            function validateForm() {
                const doctorRating = document.getElementById('doctor-rating-input');
                const staffRating = document.getElementById('staff-rating-input');
                const submitBtn = document.getElementById('submit-feedback');
                
                let isValid = true;
                
                // Check doctor rating if doctor feedback section exists
                if (doctorRating && (!doctorRating.value || doctorRating.value < 1 || doctorRating.value > 10)) {
                    isValid = false;
                }
                
                // Check staff rating if staff feedback section exists
                if (staffRating && (!staffRating.value || staffRating.value < 1 || staffRating.value > 10)) {
                    isValid = false;
                }
                
                submitBtn.disabled = !isValid;
            }
            
            // Form submission
            document.getElementById('feedback-form').addEventListener('submit', function(e) {
                const doctorRating = document.getElementById('doctor-rating-input');
                const staffRating = document.getElementById('staff-rating-input');
                
                // Validate doctor rating
                if (doctorRating && (!doctorRating.value || doctorRating.value < 1 || doctorRating.value > 10)) {
                    e.preventDefault();
                    document.getElementById('doctor-rating-error').style.display = 'block';
                    return false;
                }
                
                // Validate staff rating
                if (staffRating && (!staffRating.value || staffRating.value < 1 || staffRating.value > 10)) {
                    e.preventDefault();
                    document.getElementById('staff-rating-error').style.display = 'block';
                    return false;
                }
                
                // Show loading state
                const submitBtn = document.getElementById('submit-feedback');
                submitBtn.innerHTML = '<i class="fa fa-spinner fa-spin"></i> Submitting...';
                submitBtn.disabled = true;
            });
            
            // Auto-dismiss alerts
            setTimeout(function() {
                const alerts = document.querySelectorAll('.alert');
                alerts.forEach(function(alert) {
                    alert.style.display = 'none';
                });
            }, 5000);
        });
    </script>

</body>
</html>
