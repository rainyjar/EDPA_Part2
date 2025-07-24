/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

import java.io.IOException;
import java.sql.Time;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Date;
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
import model.Customer;
import model.Doctor;
import model.DoctorFacade;
import model.Treatment;
import model.TreatmentFacade;

/**
 *
 * @author chris
 */
@WebServlet(urlPatterns = {"/AppointmentServlet"})
public class AppointmentServlet extends HttpServlet {

    @EJB
    private AppointmentFacade appointmentFacade;

    @EJB
    private DoctorFacade doctorFacade;

    @EJB
    private TreatmentFacade treatmentFacade;

    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String action = request.getParameter("action");
        HttpSession session = request.getSession();
        Customer customer = (Customer) session.getAttribute("customer");

        if ("viewAll".equals(action)) {
            List<Appointment> appointments = appointmentFacade.findAll();
            request.setAttribute("appointments", appointments);
            request.getRequestDispatcher("manager/view_apt.jsp").forward(request, response);

        } else if ("loadReschedule".equals(action)) {
            handleLoadReschedule(request, response);

        } else if (action == null || "book".equals(action)) {
            // Show form for booking
            request.setAttribute("doctorList", doctorFacade.findAll());
            request.setAttribute("treatmentList", treatmentFacade.findAll());
            request.getRequestDispatcher("customer/appointment.jsp").forward(request, response);
        }
    }

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String action = request.getParameter("action");

        if ("cancel".equals(action)) {
            handleCancelAppointment(request, response);

        } else if ("reschedule".equals(action)) {
            handleRescheduleAppointment(request, response);

        } else {
            HttpSession session = request.getSession();
            Customer customer = (Customer) session.getAttribute("customer");

            try {
                int doctorId = Integer.parseInt(request.getParameter("doctor_id"));
                int treatmentId = Integer.parseInt(request.getParameter("treatment_id"));
                String custMessage = request.getParameter("customer_message");
                String dateStr = request.getParameter("appointment_date"); // e.g., "2025-07-24"
                String timeStr = request.getParameter("appointment_time"); // e.g., "14:30"

                Date appointmentDate = null;
                Time appointmentTime = null;

                try {
                    SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd");
                    appointmentDate = dateFormat.parse(dateStr);

                    appointmentTime = Time.valueOf(timeStr + ":00"); // convert to HH:mm:ss
                } catch (Exception e) {
                    e.printStackTrace();
                }

                Appointment appt = new Appointment();
                appt.setAppointmentDate(appointmentDate);
                appt.setAppointmentTime(appointmentTime);
                appt.setCustMessage(custMessage);
                appt.setStatus("Pending");
                appt.setCustomer(customer);
                appt.setDoctor(doctorFacade.find(doctorId));
                appt.setTreatment(treatmentFacade.find(treatmentId));

                appointmentFacade.create(appt);

                response.sendRedirect("AppointmentServlet?action=viewAll");

            } catch (Exception e) {
                e.printStackTrace();
                request.setAttribute("error", "Failed to book appointment. Please check inputs.");
                doGet(request, response); // return to form
            }
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
//    protected void doPost(HttpServletRequest request, HttpServletResponse response)
//            throws ServletException, IOException {
//        processRequest(request, response);
//    }
    /**
     * Returns a short description of the servlet.
     *
     * @return a String containing servlet description
     */
    @Override
    public String getServletInfo() {
        return "Short description";
    }// </editor-fold>

}
