/*
 * Comprehensive Appointment Servlet for APU Medical Center
 * Handles all appointment operations: booking, canceling, rescheduling, and data loading
 */

import java.io.IOException;
import java.sql.Time;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.time.LocalDate;
import java.util.Date;
import java.util.List;
import java.util.Random;
import javax.ejb.EJB;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import model.Appointment;
import model.AppointmentFacade;
import model.Customer;
import model.Doctor;
import model.DoctorFacade;
import model.Treatment;
import model.TreatmentFacade;
import model.CounterStaff;
import model.CounterStaffFacade;

@WebServlet(urlPatterns = {"/AppointmentServlet"})
public class AppointmentServlet extends HttpServlet {

    @EJB
    private AppointmentFacade appointmentFacade;

    @EJB
    private DoctorFacade doctorFacade;

    @EJB
    private TreatmentFacade treatmentFacade;

    @EJB
    private CounterStaffFacade counterStaffFacade;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String action = request.getParameter("action");

        // Check if user is logged in for customer actions
        HttpSession session = request.getSession();
        Customer loggedInCustomer = (Customer) session.getAttribute("customer");

        if ("view".equals(action)) {
            // Manager view - show all appointments
            List<Appointment> appointments = appointmentFacade.findAll();
            request.setAttribute("appointments", appointments);
            request.getRequestDispatcher("manager/view_apt.jsp").forward(request, response);

        } else if ("reschedule".equals(action)) {
            // Load reschedule form
            handleLoadReschedule(request, response);
        } else if (action == null || "book".equals(action)) {
            // Show form for booking
            request.setAttribute("doctorList", doctorFacade.findAll());
            request.setAttribute("treatmentList", treatmentFacade.findAll());
            request.getRequestDispatcher("customer/appointment.jsp").forward(request, response);
        } else {
            // Default: Load appointment booking form
            if (loggedInCustomer == null) {
                response.sendRedirect(request.getContextPath() + "/login.jsp");
                return;
            }

            try {
                // Load data for appointment form
                loadAppointmentFormData(request, response);

                // Forward to appointment JSP
                request.getRequestDispatcher("/customer/appointment.jsp").forward(request, response);

            } catch (Exception e) {
                e.printStackTrace();
                response.sendRedirect(request.getContextPath() + "/customer/cust_homepage.jsp?error=load_failed");
            }
        }
    }

    /**
     * Load necessary data for appointment form
     */
    private void loadAppointmentFormData(HttpServletRequest request, HttpServletResponse response) {
        try {
            // Load all treatments
            List<Treatment> treatmentList = treatmentFacade.findAll();
            request.setAttribute("treatmentList", treatmentList);

            // Load all doctors
            List<Doctor> doctorList = doctorFacade.findAll();
            request.setAttribute("doctorList", doctorList);

            // Log for debugging
            System.out.println("=== APPOINTMENT DATA LOADED ===");
            System.out.println("Treatments loaded: " + (treatmentList != null ? treatmentList.size() : 0));
            System.out.println("Doctors loaded: " + (doctorList != null ? doctorList.size() : 0));
            System.out.println("===============================");

        } catch (Exception e) {
            e.printStackTrace();
            System.out.println("Error loading appointment form data: " + e.getMessage());
        }
    }

    private void handleLoadReschedule(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        try {
            String appointmentIdStr = request.getParameter("id");

            if (appointmentIdStr == null || appointmentIdStr.trim().isEmpty()) {
                response.sendRedirect("customer/appointment_history.jsp?error=invalid_id");
                return;
            }

            int appointmentId = Integer.parseInt(appointmentIdStr);

            // Find the appointment
            Appointment appointment = appointmentFacade.find(appointmentId);
            if (appointment == null) {
                response.sendRedirect("customer/appointment_history.jsp?error=not_found");
                return;
            }

            // Validate that appointment can be rescheduled (only pending or approved)
            String status = appointment.getStatus();
            if (!"pending".equals(status) && !"approved".equals(status)) {
                response.sendRedirect("customer/appointment_history.jsp?error=cannot_reschedule");
                return;
            }

            // Load necessary data for the reschedule form
            // TODO: Load doctors, treatments lists similar to how appointment.jsp does it
            // For now, we'll assume these are loaded via separate servlets or included files
            request.setAttribute("existingAppointment", appointment);
            request.getRequestDispatcher("customer/appointment_reschedule.jsp").forward(request, response);

        } catch (NumberFormatException e) {
            response.sendRedirect("customer/appointment_history.jsp?error=invalid_id");
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("customer/appointment_history.jsp?error=system_error");
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String action = request.getParameter("action");

        if ("book".equals(action)) {
            handleBookAppointment(request, response);
        } else if ("cancel".equals(action)) {
            handleCancelAppointment(request, response);
        } else if ("reschedule".equals(action)) {
            handleRescheduleAppointment(request, response);
        } else {
            response.sendRedirect(request.getContextPath() + "/customer/appointment.jsp");
        }
    }

    /**
     * Handle appointment booking request
     */
    private void handleBookAppointment(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        try {
            // Get customer from session
            HttpSession session = request.getSession();
            Customer loggedInCustomer = (Customer) session.getAttribute("customer");

            if (loggedInCustomer == null) {
                response.sendRedirect(request.getContextPath() + "/login.jsp");
                return;
            }

            // Extract form parameters
            String treatmentIdStr = request.getParameter("treatment_id");
            String doctorIdStr = request.getParameter("doctor_id");
            String appointmentDateStr = request.getParameter("appointment_date");
            String appointmentTimeStr = request.getParameter("appointment_time");
            String customerMessage = request.getParameter("customer_message");

            // Validate required fields
            ValidationResult validation = validateBookingData(
                    treatmentIdStr, doctorIdStr, appointmentDateStr, appointmentTimeStr
            );

            if (!validation.isValid()) {
                response.sendRedirect(request.getContextPath() + "/customer/appointment.jsp?error=" + validation.getErrorCode());
                return;
            }

            // Parse and validate data
            int treatmentId = Integer.parseInt(treatmentIdStr);
            int doctorId = Integer.parseInt(doctorIdStr);
            Date appointmentDate = parseDate(appointmentDateStr);
            Time appointmentTime = parseTime(appointmentTimeStr);

            // Validate entities exist
            Treatment treatment = treatmentFacade.find(treatmentId);
            Doctor doctor = doctorFacade.find(doctorId);

            if (treatment == null || doctor == null) {
                response.sendRedirect(request.getContextPath() + "/customer/appointment.jsp?error=invalid_selection");
                return;
            }

            // Validate appointment date (must be future date, weekday, within one week)
            if (!isValidAppointmentDate(appointmentDate)) {
                response.sendRedirect(request.getContextPath() + "/customer/appointment.jsp?error=invalid_date");
                return;
            }

            // Validate appointment time (9 AM - 5 PM, 30-minute slots)
            if (!isValidAppointmentTime(appointmentTime)) {
                response.sendRedirect(request.getContextPath() + "/customer/appointment.jsp?error=invalid_time");
                return;
            }

            // Check for existing appointment conflicts
            if (hasAppointmentConflict(doctorId, appointmentDate, appointmentTime)) {
                response.sendRedirect(request.getContextPath() + "/customer/appointment.jsp?error=time_conflict");
                return;
            }

            // Assign counter staff (random assignment for now)
            CounterStaff assignedStaff = assignCounterStaff();

            // Create new appointment
            Appointment newAppointment = new Appointment();
            newAppointment.setCustomer(loggedInCustomer);
            newAppointment.setDoctor(doctor);
            newAppointment.setTreatment(treatment);
            newAppointment.setCounterStaff(assignedStaff);
            newAppointment.setAppointmentDate(appointmentDate);
            newAppointment.setAppointmentTime(appointmentTime);
            newAppointment.setCustMessage(customerMessage != null ? customerMessage.trim() : "");
            newAppointment.setStatus("pending"); // Default status
            newAppointment.setDocMessage(null); // Will be set after consultation

            // Save appointment
            appointmentFacade.create(newAppointment);

            // Log successful booking
            System.out.println("=== APPOINTMENT BOOKED SUCCESSFULLY ===");
            System.out.println("Customer: " + loggedInCustomer.getName());
            System.out.println("Doctor: " + doctor.getName());
            System.out.println("Treatment: " + treatment.getName());
            System.out.println("Date: " + appointmentDate);
            System.out.println("Time: " + appointmentTime);
            System.out.println("Status: pending");
            System.out.println("======================================");

            // Redirect to success page or appointment history
            response.sendRedirect(request.getContextPath() + "/customer/appointment_history.jsp?success=booked");

        } catch (NumberFormatException e) {
            response.sendRedirect(request.getContextPath() + "/customer/appointment.jsp?error=invalid_data");
        } catch (ParseException e) {
            response.sendRedirect(request.getContextPath() + "/customer/appointment.jsp?error=invalid_datetime");
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + "/customer/appointment.jsp?error=booking_failed");
        }
    }

    private void handleCancelAppointment(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        try {
            String appointmentIdStr = request.getParameter("appointmentId");
            String currentStatus = request.getParameter("currentStatus");

            if (appointmentIdStr == null || appointmentIdStr.trim().isEmpty()) {
                response.sendRedirect("customer/appointment_history.jsp?error=invalid_id");
                return;
            }

            int appointmentId = Integer.parseInt(appointmentIdStr);

            // Find the appointment
            Appointment appointment = appointmentFacade.find(appointmentId);
            if (appointment == null) {
                response.sendRedirect("customer/appointment_history.jsp?error=not_found");
                return;
            }

            // Validate that appointment can be cancelled (only pending or approved)
            String status = appointment.getStatus();
            if (!"pending".equals(status) && !"approved".equals(status)) {
                response.sendRedirect("customer/appointment_history.jsp?error=cannot_cancel");
                return;
            }

            // Update appointment status to cancelled
            appointment.setStatus("cancelled");
            appointmentFacade.edit(appointment);

            // Redirect back to appointment history with success message
            response.sendRedirect("customer/appointment_history.jsp?success=cancelled");

        } catch (NumberFormatException e) {
            response.sendRedirect("customer/appointment_history.jsp?error=invalid_id");
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("customer/appointment_history.jsp?error=system_error");
        }
    }

    private void handleRescheduleAppointment(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        try {
            String appointmentIdStr = request.getParameter("appointmentId");
            String originalStatus = request.getParameter("originalStatus");
            String treatmentIdStr = request.getParameter("treatment_id");
            String doctorIdStr = request.getParameter("doctor_id");
            String appointmentDate = request.getParameter("appointment_date");
            String appointmentTime = request.getParameter("appointment_time");
            String message = request.getParameter("message");

            if (appointmentIdStr == null || appointmentIdStr.trim().isEmpty()) {
                response.sendRedirect("customer/appointment_reschedule.jsp?error=invalid_id");
                return;
            }

            int appointmentId = Integer.parseInt(appointmentIdStr);

            // Find the appointment
            Appointment appointment = appointmentFacade.find(appointmentId);
            if (appointment == null) {
                response.sendRedirect("customer/appointment_history.jsp?error=not_found");
                return;
            }

            // Validate that appointment can be rescheduled (only pending or approved)
            String currentStatus = appointment.getStatus();
            if (!"pending".equals(currentStatus) && !"approved".equals(currentStatus)) {
                response.sendRedirect("customer/appointment_history.jsp?error=cannot_reschedule");
                return;
            }

            // Update appointment details
            if (treatmentIdStr != null && !treatmentIdStr.trim().isEmpty()) {
                int treatmentId = Integer.parseInt(treatmentIdStr);
                Treatment treatment = treatmentFacade.find(treatmentId);
                if (treatment != null) {
                    appointment.setTreatment(treatment);
                }
            }
            if (doctorIdStr != null && !doctorIdStr.trim().isEmpty()) {
                int doctorId = Integer.parseInt(doctorIdStr);
                Doctor doctor = doctorFacade.find(doctorId);
                if (doctor != null) {
                    appointment.setDoctor(doctor);
                }
            }
            if (appointmentDate != null && !appointmentDate.trim().isEmpty()) {
                try {
                    SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd");
                    Date date = dateFormat.parse(appointmentDate);
                    appointment.setAppointmentDate(date);
                } catch (ParseException e) {
                    response.sendRedirect("customer/appointment_reschedule.jsp?error=invalid_date");
                    return;
                }
            }
            if (appointmentTime != null && !appointmentTime.trim().isEmpty()) {
                try {
                    // Convert time string (HH:mm) to Time object
                    SimpleDateFormat timeFormat = new SimpleDateFormat("HH:mm");
                    Date timeDate = timeFormat.parse(appointmentTime);
                    Time time = new Time(timeDate.getTime());
                    appointment.setAppointmentTime(time);
                } catch (ParseException e) {
                    response.sendRedirect("customer/appointment_reschedule.jsp?error=invalid_time");
                    return;
                }
            }
            if (message != null) {
                appointment.setCustMessage(message);
            }

            // Set status based on original status
            if ("approved".equals(originalStatus)) {
                // If was approved, change back to pending for new approval
                appointment.setStatus("pending");
            } else {
                // If was pending, keep as pending
                appointment.setStatus("pending");
            }

            // Clear doctor's message as it's a new/modified appointment
            appointment.setDocMessage(null);

            appointmentFacade.edit(appointment);

            // Redirect back to appointment history with success message
            response.sendRedirect("customer/appointment_history.jsp?success=rescheduled");

        } catch (NumberFormatException e) {
            response.sendRedirect("customer/appointment_reschedule.jsp?error=invalid_data");
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("customer/appointment_reschedule.jsp?error=system_error");
        }
    }

    // <editor-fold defaultstate="collapsed" desc="HttpServlet methods. Click on the + sign on the left to edit the code.">
    /**
     * Handles the HTTP <code>GET</code> method.
     *
     * @param request servlet request
     * @param response servlet response
     * @throws ServletException if a servlet-specific error occurs
     * @throws IOException if an I/O error occurs
     */
//    @Override
//    protected void doGet(HttpServletRequest request, HttpServletResponse response)
//            throws ServletException, IOException {
//        processRequest(request, response);
//    }
//
//    /**
//     * Handles the HTTP <code>POST</code> method.
//     *
//     * @param request servlet request
//     * @param response servlet response
//     * @throws ServletException if a servlet-specific error occurs
//     * @throws IOException if an I/O error occurs
//     */
//    @Override
    /**
     * Validate booking form data
     */
    private ValidationResult validateBookingData(String treatmentId, String doctorId,
            String appointmentDate, String appointmentTime) {

        if (treatmentId == null || treatmentId.trim().isEmpty()) {
            return new ValidationResult(false, "missing_treatment");
        }

        if (doctorId == null || doctorId.trim().isEmpty()) {
            return new ValidationResult(false, "missing_doctor");
        }

        if (appointmentDate == null || appointmentDate.trim().isEmpty()) {
            return new ValidationResult(false, "missing_date");
        }

        if (appointmentTime == null || appointmentTime.trim().isEmpty()) {
            return new ValidationResult(false, "missing_time");
        }

        // Validate numeric IDs
        try {
            Integer.parseInt(treatmentId);
            Integer.parseInt(doctorId);
        } catch (NumberFormatException e) {
            return new ValidationResult(false, "invalid_ids");
        }

        return new ValidationResult(true, null);
    }

    /**
     * Parse date string to Date object
     */
    private Date parseDate(String dateStr) throws ParseException {
        SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd");
        return dateFormat.parse(dateStr);
    }

    /**
     * Parse time string to Time object
     */
    private Time parseTime(String timeStr) throws ParseException {
        SimpleDateFormat timeFormat = new SimpleDateFormat("HH:mm");
        Date timeDate = timeFormat.parse(timeStr);
        return new Time(timeDate.getTime());
    }

    /**
     * Validate appointment date is in the future and within allowed range
     */
    private boolean isValidAppointmentDate(Date appointmentDate) {
        LocalDate today = LocalDate.now();
        LocalDate appointmentLocalDate = appointmentDate.toInstant()
                .atZone(java.time.ZoneId.systemDefault())
                .toLocalDate();

        // Check if date is in the future (from today)
        if (!appointmentLocalDate.isAfter(today.minusDays(1))) {
            return false;
        }

        // Check if date is within one week from today
        LocalDate nextWeek = today.plusDays(7);
        if (appointmentLocalDate.isAfter(nextWeek)) {
            return false;
        }

        // Check if date is a weekday (Monday = 1, Friday = 5)
        int dayOfWeek = appointmentLocalDate.getDayOfWeek().getValue();
        if (dayOfWeek > 5) { // Saturday = 6, Sunday = 7
            return false;
        }

        return true;
    }

    /**
     * Validate appointment time is within business hours (9 AM - 5 PM) and in
     * 30-minute slots
     */
    private boolean isValidAppointmentTime(Time appointmentTime) {
        if (appointmentTime == null) {
            return false;
        }

        // Get hour and minute from Time
        String timeStr = appointmentTime.toString(); // Format: HH:mm:ss
        String[] timeParts = timeStr.split(":");
        int hour = Integer.parseInt(timeParts[0]);
        int minute = Integer.parseInt(timeParts[1]);

        // Check business hours: 9 AM (09:00) to 5 PM (17:00)
        if (hour < 9 || hour >= 17) {
            return false;
        }

        // Check if minute is in valid 30-minute slots (00 or 30)
        if (minute != 0 && minute != 30) {
            return false;
        }

        return true;
    }

    /**
     * Check for appointment time conflicts
     */
    private boolean hasAppointmentConflict(int doctorId, Date appointmentDate, Time appointmentTime) {
        try {
            List<Appointment> existingAppointments = appointmentFacade.findAll();

            for (Appointment appointment : existingAppointments) {
                if (appointment.getDoctor() != null
                        && appointment.getDoctor().getId() == doctorId
                        && appointment.getAppointmentDate() != null
                        && appointment.getAppointmentTime() != null
                        && !("cancelled".equals(appointment.getStatus()))) {

                    // Check if same date and time
                    if (isSameDate(appointment.getAppointmentDate(), appointmentDate)
                            && isSameTime(appointment.getAppointmentTime(), appointmentTime)) {
                        return true; // Conflict found
                    }
                }
            }

            return false; // No conflict

        } catch (Exception e) {
            e.printStackTrace();
            return true; // Assume conflict on error for safety
        }
    }

    /**
     * Check if two dates are the same day
     */
    private boolean isSameDate(Date date1, Date date2) {
        SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd");
        return dateFormat.format(date1).equals(dateFormat.format(date2));
    }

    /**
     * Check if two times are the same
     */
    private boolean isSameTime(Time time1, Time time2) {
        return time1.toString().equals(time2.toString());
    }

    /**
     * Assign a counter staff (random assignment for now) In a real system, this
     * could be based on workload, availability, etc.
     */
    private CounterStaff assignCounterStaff() {
        try {
            List<CounterStaff> staffList = counterStaffFacade.findAll();

            if (staffList != null && !staffList.isEmpty()) {
                // Random assignment
                Random random = new Random();
                int randomIndex = random.nextInt(staffList.size());
                return staffList.get(randomIndex);
            }

            return null; // No staff available

        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }
    }

    /**
     * Inner class for validation results
     */
    private static class ValidationResult {

        private final boolean valid;
        private final String errorCode;

        public ValidationResult(boolean valid, String errorCode) {
            this.valid = valid;
            this.errorCode = errorCode;
        }

        public boolean isValid() {
            return valid;
        }

        public String getErrorCode() {
            return errorCode;
        }
    }

    /**
     * Returns a short description of the servlet.
     *
     * @return a String containing servlet description
     */
    @Override
    public String getServletInfo() {
        return "AppointmentServlet handles all appointment operations: booking, canceling, rescheduling, and data loading";
    }

}
