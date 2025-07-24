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
 * ScheduleServlet handles feedback operations for the APU Medical Center
 * This servlet manages feedback submission and validation for completed appointments
 */
@WebServlet(name = "ScheduleServlet", urlPatterns = {"/ScheduleServlet"})
public class ScheduleServlet extends HttpServlet {

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
            response.sendRedirect(request.getContextPath() + "/customer/appointment_history.jsp");
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        String action = request.getParameter("action");
        
        if ("submit_feedback".equals(action)) {
            handleSubmitFeedback(request, response);
        } else {
            response.sendRedirect(request.getContextPath() + "/customer/appointment_history.jsp");
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
            
            // Get appointment details
            Appointment appointment = appointmentFacade.find(appointmentId);
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
            
            // Validate appointment is completed
            if (!"completed".equals(appointment.getStatus())) {
                response.sendRedirect(request.getContextPath() + "/customer/appointment_history.jsp?error=not_completed");
                return;
            }
            
            // Check if feedback already exists for this appointment
            boolean feedbackExists = checkFeedbackExists(appointmentId);
            if (feedbackExists) {
                response.sendRedirect(request.getContextPath() + "/customer/appointment_history.jsp?error=feedback_exists");
                return;
            }
            
            // Set appointment data and forward to feedback form
            request.setAttribute("appointment", appointment);
            request.setAttribute("feedbackExists", feedbackExists);
            request.getRequestDispatcher("/customer/feedback.jsp").forward(request, response);
            
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + "/customer/appointment_history.jsp?error=system_error");
        }
    }
    
    /**
     * Handle feedback submission
     * Validates data and creates feedback records for doctor and/or counter staff
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
                response.sendRedirect(request.getContextPath() + "/customer/appointment_history.jsp?error=appointment_not_found");
                return;
            }
            
            // Validate appointment belongs to logged-in customer and is completed
            if (appointment.getCustomer() == null || 
                appointment.getCustomer().getId() != loggedInCustomer.getId() ||
                !"completed".equals(appointment.getStatus())) {
                response.sendRedirect(request.getContextPath() + "/customer/appointment_history.jsp?error=unauthorized");
                return;
            }
            
            // Check if feedback already exists
            if (checkFeedbackExists(appointmentId)) {
                response.sendRedirect(request.getContextPath() + "/customer/appointment_history.jsp?error=feedback_exists");
                return;
            }
            
            // Get feedback parameters
            String doctorRatingParam = request.getParameter("doctor_rating");
            String staffRatingParam = request.getParameter("staff_rating");
            String doctorComment = request.getParameter("doctor_comment");
            String staffComment = request.getParameter("staff_comment");
            
            boolean hasValidFeedback = false;
            
            // Process doctor feedback if provided
            if (appointment.getDoctor() != null && doctorRatingParam != null && !doctorRatingParam.trim().isEmpty()) {
                try {
                    int doctorRating = Integer.parseInt(doctorRatingParam);
                    if (doctorRating >= 1 && doctorRating <= 10) {
                        // Create doctor feedback
                        Feedback doctorFeedback = new Feedback();
                        doctorFeedback.setAppointment(appointment);
                        doctorFeedback.setFromCustomer(loggedInCustomer);
                        doctorFeedback.setToDoctor(appointment.getDoctor());
                        doctorFeedback.setToStaff(null);
                        doctorFeedback.setRating(doctorRating);
                        doctorFeedback.setCustComment(doctorComment != null ? doctorComment.trim() : "");
                        
                        feedbackFacade.create(doctorFeedback);
                        hasValidFeedback = true;
                        
                        // Update doctor's overall rating
                        updateDoctorRating(appointment.getDoctor().getId());
                        
                        System.out.println("Doctor feedback created successfully for appointment: " + appointmentId);
                    }
                } catch (NumberFormatException e) {
                    response.sendRedirect(request.getContextPath() + "/customer/feedback.jsp?appointment_id=" + appointmentId + "&error=invalid_rating");
                    return;
                }
            }
            
            // Process counter staff feedback if provided
            if (appointment.getCounterStaff() != null && staffRatingParam != null && !staffRatingParam.trim().isEmpty()) {
                try {
                    int staffRating = Integer.parseInt(staffRatingParam);
                    if (staffRating >= 1 && staffRating <= 10) {
                        // Create staff feedback
                        Feedback staffFeedback = new Feedback();
                        staffFeedback.setAppointment(appointment);
                        staffFeedback.setFromCustomer(loggedInCustomer);
                        staffFeedback.setToDoctor(null);
                        staffFeedback.setToStaff(appointment.getCounterStaff());
                        staffFeedback.setRating(staffRating);
                        staffFeedback.setCustComment(staffComment != null ? staffComment.trim() : "");
                        
                        feedbackFacade.create(staffFeedback);
                        hasValidFeedback = true;
                        
                        // Update counter staff's overall rating
                        updateCounterStaffRating(appointment.getCounterStaff().getId());
                        
                        System.out.println("Staff feedback created successfully for appointment: " + appointmentId);
                    }
                } catch (NumberFormatException e) {
                    response.sendRedirect(request.getContextPath() + "/customer/feedback.jsp?appointment_id=" + appointmentId + "&error=invalid_rating");
                    return;
                }
            }
            
            if (hasValidFeedback) {
                // Redirect to appointment history with success message
                response.sendRedirect(request.getContextPath() + "/customer/appointment_history.jsp?success=feedback_submitted");
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
     * Check if feedback already exists for the given appointment
     */
    private boolean checkFeedbackExists(int appointmentId) {
        return feedbackFacade.feedbackExistsForAppointment(appointmentId);
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
        return "ScheduleServlet handles feedback operations for APU Medical Center";
    }
}
