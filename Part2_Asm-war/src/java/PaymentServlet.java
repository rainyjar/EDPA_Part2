import java.io.IOException;
import java.text.DecimalFormat;
import java.text.SimpleDateFormat;
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
import model.CounterStaff;
import model.Doctor;
import model.Payment;
import model.PaymentFacade;

/**
 * PaymentServlet handles payment operations for the APU Medical Center
 * This servlet manages payment processing for both doctors and counter staff
 */
@WebServlet(name = "PaymentServlet", urlPatterns = {"/PaymentServlet"})
public class PaymentServlet extends HttpServlet {

    @EJB
    private AppointmentFacade appointmentFacade;
    
    @EJB
    private PaymentFacade paymentFacade;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        String action = request.getParameter("action");
        
        switch (action != null ? action : "") {
            case "viewAssignedAppointments":
                handleViewAssignedAppointments(request, response);
                break;
            case "viewPayments":
                handleViewPayments(request, response);
                break;
            case "getAppointmentDetails":
                handleGetAppointmentDetails(request, response);
                break;
            default:
                response.sendRedirect(request.getContextPath() + "/login.jsp");
                break;
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        String action = request.getParameter("action");
        
        switch (action != null ? action : "") {
            case "completeAppointment":
                handleCompleteAppointment(request, response);
                break;
            case "processPayment":
                handleProcessPayment(request, response);
                break;
            default:
                response.sendRedirect(request.getContextPath() + "/login.jsp");
                break;
        }
    }
    
    /**
     * Handle viewing assigned appointments for doctors
     */
    private void handleViewAssignedAppointments(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        try {
            HttpSession session = request.getSession();
            Doctor loggedInDoctor = (Doctor) session.getAttribute("doctor");
            
            if (loggedInDoctor == null) {
                response.sendRedirect(request.getContextPath() + "/login.jsp");
                return;
            }
            
            // Get all approved appointments assigned to this doctor
            List<Appointment> appointments = appointmentFacade.findByDoctorAndStatus(loggedInDoctor.getId(), "approved");
            
            // Also get completed appointments for reference
            List<Appointment> completedAppointments = appointmentFacade.findByDoctorAndStatus(loggedInDoctor.getId(), "completed");
            appointments.addAll(completedAppointments);
            
            request.setAttribute("appointments", appointments);
            request.setAttribute("doctor", loggedInDoctor);
            
            // Set date and time formatters for JSP
            request.setAttribute("dateFormat", new SimpleDateFormat("yyyy-MM-dd"));
            request.setAttribute("timeFormat", new SimpleDateFormat("HH:mm"));
            
            request.getRequestDispatcher("/doctor/doctor_assigned.jsp").forward(request, response);
            
        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Failed to load assigned appointments: " + e.getMessage());
            request.getRequestDispatcher("/doctor/doctor_assigned.jsp").forward(request, response);
        }
    }
    
    /**
     * Handle viewing payments for counter staff
     */
    private void handleViewPayments(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        try {
            HttpSession session = request.getSession();
            CounterStaff loggedInStaff = (CounterStaff) session.getAttribute("staff");
            
            if (loggedInStaff == null) {
                response.sendRedirect(request.getContextPath() + "/login.jsp");
                return;
            }
            
            String statusFilter = request.getParameter("status");
            if (statusFilter == null || statusFilter.trim().isEmpty()) {
                statusFilter = "pending"; // Default to show pending payments
            }
            
            // Debug logging
            System.out.println("PaymentServlet - Status filter: " + statusFilter);
            
            List<Payment> payments;
            if ("all".equals(statusFilter)) {
                payments = paymentFacade.findAll();
                System.out.println("PaymentServlet - Found all payments: " + (payments != null ? payments.size() : 0));
            } else {
                payments = paymentFacade.findByStatus(statusFilter);
                System.out.println("PaymentServlet - Found payments with status '" + statusFilter + "': " + (payments != null ? payments.size() : 0));
            }
            
            // Debug: Print payment details
            if (payments != null) {
                for (Payment p : payments) {
                    System.out.println("Payment ID: " + p.getId() + ", Status: " + p.getStatus() + ", Amount: " + p.getAmount());
                }
            }
            
            // Also get appointments for completed appointments that have pending payments
            List<Appointment> completedAppointments = appointmentFacade.findByStatus("completed");
            
            request.setAttribute("payments", payments);
            request.setAttribute("completedAppointments", completedAppointments);
            request.setAttribute("statusFilter", statusFilter);
            request.setAttribute("staff", loggedInStaff);
            
            // Set formatters
            request.setAttribute("dateFormat", new SimpleDateFormat("yyyy-MM-dd"));
            request.setAttribute("timeFormat", new SimpleDateFormat("HH:mm"));
            request.setAttribute("decimalFormat", new DecimalFormat("#0.00"));
            
            request.getRequestDispatcher("/counter_staff/staff_payment.jsp").forward(request, response);
            
        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Failed to load payments: " + e.getMessage());
            request.getRequestDispatcher("/counter_staff/staff_payment.jsp").forward(request, response);
        }
    }
    
    /**
     * Handle completing an appointment and creating payment record
     */
    private void handleCompleteAppointment(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        try {
            HttpSession session = request.getSession();
            Doctor loggedInDoctor = (Doctor) session.getAttribute("doctor");
            
            if (loggedInDoctor == null) {
                response.sendRedirect(request.getContextPath() + "/login.jsp");
                return;
            }
            
            // Get parameters
            int appointmentId = Integer.parseInt(request.getParameter("appointmentId"));
            String doctorNotes = request.getParameter("doctorNotes");
            double paymentAmount = Double.parseDouble(request.getParameter("paymentAmount"));
            
            // Validate payment amount
            if (paymentAmount < 0) {
                request.setAttribute("error", "Payment amount cannot be negative");
                handleViewAssignedAppointments(request, response);
                return;
            }
            
            // Get appointment
            Appointment appointment = appointmentFacade.find(appointmentId);
            if (appointment == null) {
                request.setAttribute("error", "Appointment not found");
                handleViewAssignedAppointments(request, response);
                return;
            }
            
            // Validate doctor owns this appointment
            if (appointment.getDoctor() == null || appointment.getDoctor().getId() != loggedInDoctor.getId()) {
                request.setAttribute("error", "Unauthorized access to appointment");
                handleViewAssignedAppointments(request, response);
                return;
            }
            
            // Validate appointment status
            if (!"approved".equals(appointment.getStatus())) {
                request.setAttribute("error", "Only approved appointments can be completed");
                handleViewAssignedAppointments(request, response);
                return;
            }
            
            // Update appointment
            appointment.setStatus("completed");
            if (doctorNotes != null && !doctorNotes.trim().isEmpty()) {
                appointment.setDocMessage(doctorNotes.trim());
            }
            appointmentFacade.edit(appointment);
            
            // Create payment record
            Payment payment = new Payment();
            payment.setAppointment(appointment);
            payment.setAmount(paymentAmount);
            payment.setStatus("pending");
            payment.setPaymentDate(new java.util.Date());
            paymentFacade.create(payment);
            
            request.setAttribute("success", "Appointment completed successfully and charges sent to counter staff");
            handleViewAssignedAppointments(request, response);
            
        } catch (NumberFormatException e) {
            request.setAttribute("error", "Invalid appointment ID or payment amount");
            handleViewAssignedAppointments(request, response);
        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Failed to complete appointment: " + e.getMessage());
            handleViewAssignedAppointments(request, response);
        }
    }
    
    /**
     * Handle processing payment by counter staff
     */
    private void handleProcessPayment(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        try {
            HttpSession session = request.getSession();
            CounterStaff loggedInStaff = (CounterStaff) session.getAttribute("staff");
            
            if (loggedInStaff == null) {
                response.sendRedirect(request.getContextPath() + "/login.jsp");
                return;
            }
            
            // Get parameters
            int paymentId = Integer.parseInt(request.getParameter("paymentId"));
            String paymentMethod = request.getParameter("paymentMethod");
            
            // Get payment
            Payment payment = paymentFacade.find(paymentId);
            if (payment == null) {
                request.setAttribute("error", "Payment not found");
                handleViewPayments(request, response);
                return;
            }
            
            // Validate payment status
            if (!"pending".equals(payment.getStatus())) {
                request.setAttribute("error", "Only pending payments can be processed");
                handleViewPayments(request, response);
                return;
            }
            
            // Update payment
            payment.setStatus("paid");
            payment.setPaymentMethod(paymentMethod);
            payment.setPaymentDate(new java.util.Date());
            paymentFacade.edit(payment);
            
            request.setAttribute("success", "Payment processed successfully");
            handleViewPayments(request, response);
            
        } catch (NumberFormatException e) {
            request.setAttribute("error", "Invalid payment ID");
            handleViewPayments(request, response);
        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Failed to process payment: " + e.getMessage());
            handleViewPayments(request, response);
        }
    }
    
    /**
     * Handle getting appointment details for AJAX requests
     */
    private void handleGetAppointmentDetails(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        try {
            int appointmentId = Integer.parseInt(request.getParameter("appointmentId"));
            
            Appointment appointment = appointmentFacade.find(appointmentId);
            if (appointment == null) {
                response.setStatus(HttpServletResponse.SC_NOT_FOUND);
                return;
            }
            
            // Create JSON response
            StringBuilder json = new StringBuilder();
            json.append("{");
            json.append("\"id\":").append(appointment.getId()).append(",");
            json.append("\"date\":\"").append(appointment.getAppointmentDate()).append("\",");
            json.append("\"time\":\"").append(appointment.getAppointmentTime()).append("\",");
            json.append("\"status\":\"").append(appointment.getStatus()).append("\",");
            json.append("\"doctorNotes\":\"").append(appointment.getDocMessage() != null ? appointment.getDocMessage() : "").append("\",");
            json.append("\"customerName\":\"").append(appointment.getCustomer() != null ? appointment.getCustomer().getName() : "").append("\",");
            json.append("\"treatment\":\"").append(appointment.getTreatment() != null ? appointment.getTreatment().getName() : "").append("\"");
            json.append("}");
            
            response.setContentType("application/json");
            response.setCharacterEncoding("UTF-8");
            response.getWriter().write(json.toString());
            
        } catch (NumberFormatException e) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
        } catch (Exception e) {
            e.printStackTrace();
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
        }
    }
    
    @Override
    public String getServletInfo() {
        return "PaymentServlet handles payment operations for APU Medical Center";
    }
}
