import java.io.IOException;
import java.util.List;
import javax.ejb.EJB;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import model.Appointment;
import model.AppointmentFacade;
import model.CounterStaffFacade;
import model.Customer;
import model.DoctorFacade;
import model.Feedback;
import model.FeedbackFacade;

/**
 * FeedbackServlet handles feedback operations for the APU Medical Center
 * This servlet manages feedback submission and validation for completed appointments
 */
@WebServlet(name = "FeedbackServlet", urlPatterns = {"/FeedbackServlet"})
public class FeedbackServlet extends HttpServlet {

    @EJB
    private AppointmentFacade appointmentFacade;
    
    @EJB
    private FeedbackFacade feedbackFacade;
    
    @EJB
    private DoctorFacade doctorFacade;
    
    @EJB
    private CounterStaffFacade counterStaffFacade;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        String action = request.getParameter("action");
        
        if ("show_feedback_form".equals(action)) {
            handleShowFeedbackForm(request, response);
        } else {
            response.sendRedirect(request.getContextPath() + "/AppointmentServlet?action=history");
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        String action = request.getParameter("action");
        
        if ("submit_feedback".equals(action)) {
            handleSubmitFeedback(request, response);
        } else {
            response.sendRedirect(request.getContextPath() + "/AppointmentServlet?action=history");
        }
    }
    
    /**
     * Handle showing the feedback form
     * Validates appointment eligibility and loads necessary data
     */
    private void handleShowFeedbackForm(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        try {
            // Get customer from session
            HttpSession session = request.getSession();
            Customer loggedInCustomer = (Customer) session.getAttribute("customer");
            
            if (loggedInCustomer == null) {
                response.sendRedirect(request.getContextPath() + "/login.jsp");
                return;
            }
            
            // Get and validate appointment ID
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
            
            // Get appointment details
            Appointment appointment = appointmentFacade.find(appointmentId);
            if (appointment == null) {
                response.sendRedirect(request.getContextPath() + "/AppointmentServlet?action=history&error=appointment_not_found");
                return;
            }
            
            // Validate appointment belongs to logged-in customer
            if (appointment.getCustomer() == null || 
                appointment.getCustomer().getId() != loggedInCustomer.getId()) {
                response.sendRedirect(request.getContextPath() + "/AppointmentServlet?action=history&error=unauthorized");
                return;
            }
            
            // Validate appointment is completed
            if (!"completed".equals(appointment.getStatus())) {
                response.sendRedirect(request.getContextPath() + "/AppointmentServlet?action=history&error=not_completed");
                return;
            }
            
            // Check if feedback already exists for this appointment
            Feedback existingFeedback = getExistingFeedback(appointmentId);
            
            // Set appointment data and existing feedback (if any) and forward to feedback form
            request.setAttribute("appointment", appointment);
            request.setAttribute("existingFeedback", existingFeedback);
            request.getRequestDispatcher("/customer/feedback.jsp").forward(request, response);
            
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + "/AppointmentServlet?action=history&error=system_error");
        }
    }
    
    /**
     * Handle feedback submission
     * Validates data and creates/updates feedback records
     */
    private void handleSubmitFeedback(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        try {
            // Get customer from session
            HttpSession session = request.getSession();
            Customer loggedInCustomer = (Customer) session.getAttribute("customer");
            
            if (loggedInCustomer == null) {
                response.sendRedirect(request.getContextPath() + "/login.jsp");
                return;
            }
            
            // Get and validate appointment ID
            String appointmentIdParam = request.getParameter("appointment_id");
            if (appointmentIdParam == null || appointmentIdParam.trim().isEmpty()) {
                response.sendRedirect(request.getContextPath() + "/customer/feedback.jsp?appointment_id=" + appointmentIdParam + "&error=invalid_appointment");
                return;
            }
            
            int appointmentId;
            try {
                appointmentId = Integer.parseInt(appointmentIdParam);
            } catch (NumberFormatException e) {
                response.sendRedirect(request.getContextPath() + "/customer/feedback.jsp?appointment_id=" + appointmentIdParam + "&error=invalid_appointment");
                return;
            }
            
            // Get appointment details
            Appointment appointment = appointmentFacade.find(appointmentId);
            if (appointment == null) {
                response.sendRedirect(request.getContextPath() + "/AppointmentServlet?action=history&error=appointment_not_found");
                return;
            }
            
            // Validate appointment belongs to logged-in customer and is completed
            if (appointment.getCustomer() == null || 
                appointment.getCustomer().getId() != loggedInCustomer.getId() ||
                !"completed".equals(appointment.getStatus())) {
                response.sendRedirect(request.getContextPath() + "/AppointmentServlet?action=history&error=unauthorized");
                return;
            }
            
            // Get feedback parameters
            String feedbackType = request.getParameter("feedback_type"); // "doctor" or "staff"
            String doctorRatingParam = request.getParameter("doctor_rating");
            String staffRatingParam = request.getParameter("staff_rating");
            String doctorComment = request.getParameter("doctor_comment");
            String staffComment = request.getParameter("staff_comment");
            
            // Validate feedback type
            if (!"doctor".equals(feedbackType) && !"staff".equals(feedbackType)) {
                response.sendRedirect(request.getContextPath() + "/customer/feedback.jsp?appointment_id=" + appointmentId + "&error=invalid_feedback_type");
                return;
            }
            
            // Get or create feedback record
            Feedback feedback = getExistingFeedback(appointmentId);
            if (feedback == null) {
                // Create new feedback record
                feedback = new Feedback();
                feedback.setAppointment(appointment);
                feedback.setFromCustomer(loggedInCustomer);
                feedback.setToDoctor(appointment.getDoctor());
                feedback.setToStaff(appointment.getCounterStaff());
                feedback.setDocRating(0.0); // Initialize with 0
                feedback.setStaffRating(0.0); // Initialize with 0
                feedback.setCustDocComment("");
                feedback.setCustStaffComment("");
            }
            
            boolean hasNewFeedback = false;
            
            // Process doctor feedback
            if ("doctor".equals(feedbackType)) {
                if (doctorRatingParam != null && !doctorRatingParam.trim().isEmpty()) {
                    try {
                        double doctorRating = Double.parseDouble(doctorRatingParam);
                        if (doctorRating >= 1.0 && doctorRating <= 10.0) {
                            feedback.setDocRating(doctorRating);
                            feedback.setCustDocComment(doctorComment != null ? doctorComment.trim() : "");
                            hasNewFeedback = true;
                        } else {
                            response.sendRedirect(request.getContextPath() + "/customer/feedback.jsp?appointment_id=" + appointmentId + "&error=invalid_rating");
                            return;
                        }
                    } catch (NumberFormatException e) {
                        response.sendRedirect(request.getContextPath() + "/customer/feedback.jsp?appointment_id=" + appointmentId + "&error=invalid_rating");
                        return;
                    }
                } else {
                    response.sendRedirect(request.getContextPath() + "/customer/feedback.jsp?appointment_id=" + appointmentId + "&error=rating_required");
                    return;
                }
            }
            
            // Process staff feedback
            if ("staff".equals(feedbackType)) {
                if (staffRatingParam != null && !staffRatingParam.trim().isEmpty()) {
                    try {
                        double staffRating = Double.parseDouble(staffRatingParam);
                        if (staffRating >= 1.0 && staffRating <= 10.0) {
                            feedback.setStaffRating(staffRating);
                            feedback.setCustStaffComment(staffComment != null ? staffComment.trim() : "");
                            hasNewFeedback = true;
                        } else {
                            response.sendRedirect(request.getContextPath() + "/customer/feedback.jsp?appointment_id=" + appointmentId + "&error=invalid_rating");
                            return;
                        }
                    } catch (NumberFormatException e) {
                        response.sendRedirect(request.getContextPath() + "/customer/feedback.jsp?appointment_id=" + appointmentId + "&error=invalid_rating");
                        return;
                    }
                } else {
                    response.sendRedirect(request.getContextPath() + "/customer/feedback.jsp?appointment_id=" + appointmentId + "&error=rating_required");
                    return;
                }
            }
            
            if (hasNewFeedback) {
                // Save or update feedback
                if (feedback.getId() == 0) {
                    feedbackFacade.create(feedback);
                    System.out.println("New feedback created for appointment: " + appointmentId);
                } else {
                    feedbackFacade.edit(feedback);
                    System.out.println("Feedback updated for appointment: " + appointmentId);
                }
                
                // Update ratings for doctor and/or staff
                if ("doctor".equals(feedbackType) && appointment.getDoctor() != null) {
                    updateDoctorRating(appointment.getDoctor().getId());
                }
                
                if ("staff".equals(feedbackType) && appointment.getCounterStaff() != null) {
                    updateCounterStaffRating(appointment.getCounterStaff().getId());
                }
                
                // Redirect back to feedback form with success message
                response.sendRedirect(request.getContextPath() + "/FeedbackServlet?action=show_feedback_form&appointment_id=" + appointmentId + "&success=" + feedbackType + "_submitted");
            } else {
                // No valid feedback provided
                response.sendRedirect(request.getContextPath() + "/customer/feedback.jsp?appointment_id=" + appointmentId + "&error=no_feedback");
            }
            
        } catch (Exception e) {
            e.printStackTrace();
            String appointmentId = request.getParameter("appointment_id");
            response.sendRedirect(request.getContextPath() + "/customer/feedback.jsp?appointment_id=" + appointmentId + "&error=system_error");
        }
    }
    
    /**
     * Get existing feedback for the given appointment
     */
    private Feedback getExistingFeedback(int appointmentId) {
        try {
            List<Feedback> feedbacks = feedbackFacade.findByAppointmentId(appointmentId);
            if (feedbacks != null && !feedbacks.isEmpty()) {
                return feedbacks.get(0); // Return the first (should be only one)
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }
    
    /**
     * Update doctor's overall rating based on all feedback received
     */
    private void updateDoctorRating(int doctorId) {
        try {
            double avgRating = feedbackFacade.getAverageRatingForDoctor(doctorId);
            
            if (avgRating > 0.0) {
                // Round to 2 decimal places
                double roundedRating = Math.round(avgRating * 100.0) / 100.0;
                
                // Update doctor's rating in database
                boolean success = doctorFacade.updateDoctorRating(doctorId, roundedRating);
                
                if (success) {
                    System.out.println("Doctor rating updated to: " + roundedRating + " for doctor ID: " + doctorId);
                } else {
                    System.out.println("Failed to update doctor rating for doctor ID: " + doctorId);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
            System.out.println("Error updating doctor rating: " + e.getMessage());
        }
    }
    
    /**
     * Update counter staff's overall rating based on all feedback received
     */
    private void updateCounterStaffRating(int staffId) {
        try {
            double avgRating = feedbackFacade.getAverageRatingForCounterStaff(staffId);
            
            if (avgRating > 0.0) {
                // Round to 2 decimal places
                double roundedRating = Math.round(avgRating * 100.0) / 100.0;
                
                // Update counter staff's rating in database
                boolean success = counterStaffFacade.updateCounterStaffRating(staffId, roundedRating);
                
                if (success) {
                    System.out.println("Counter staff rating updated to: " + roundedRating + " for staff ID: " + staffId);
                } else {
                    System.out.println("Failed to update counter staff rating for staff ID: " + staffId);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
            System.out.println("Error updating counter staff rating: " + e.getMessage());
        }
    }
    
    @Override
    public String getServletInfo() {
        return "FeedbackServlet handles feedback operations for APU Medical Center";
    }
}
