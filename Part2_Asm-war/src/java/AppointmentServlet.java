/*
 * Comprehensive Appointment Servlet for APU Medical Center
 * Handles all appointment operations: booking, canceling, rescheduling, and data loading
 */

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Time;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Random;
import java.util.Set;
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
import model.Schedule;
import model.ScheduleFacade;
import model.Payment;
import model.PaymentFacade;

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
    
    @EJB
    private ScheduleFacade scheduleFacade;
    
    @EJB
    private PaymentFacade paymentFacade;

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
        } else if ("getAvailableSlots".equals(action)) {
            // AJAX request to get available time slots for doctors on selected date
            handleGetAvailableSlots(request, response);
        } else if ("getDoctorsForTreatment".equals(action)) {
            // AJAX request to get doctors for a specific treatment (for reschedule form)
            handleGetDoctorsForTreatment(request, response);
        } else if ("history".equals(action)) {
            // Load appointment history page with data
            handleAppointmentHistory(request, response);
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
    
    /**
     * Handle AJAX request to get available time slots for doctors on selected date
     */
    private void handleGetAvailableSlots(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();
        
        try {
            String treatmentIdStr = request.getParameter("treatment_id");
            String selectedDate = request.getParameter("selected_date");
            
            if (treatmentIdStr == null || selectedDate == null) {
                out.write("{\"error\": \"Missing parameters\"}");
                return;
            }
            
            int treatmentId = Integer.parseInt(treatmentIdStr);
            
            // Get treatment to find related doctors by specialization
            Treatment treatment = treatmentFacade.find(treatmentId);
            if (treatment == null) {
                out.write("{\"error\": \"Treatment not found\"}");
                return;
            }
            
            // Get doctors for this treatment (assuming we have Treatment-Doctor relationship)
            List<Doctor> availableDoctors = getAvailableDoctorsForTreatment(treatmentId);
           
            // Convert date string to determine day of week
            LocalDate date = LocalDate.parse(selectedDate);
            String dayOfWeek = date.getDayOfWeek().toString(); // Returns MONDAY, TUESDAY, etc.
            
            // Convert to proper case (Monday, Tuesday, etc.) to match database format
            dayOfWeek = dayOfWeek.substring(0, 1).toUpperCase() + dayOfWeek.substring(1).toLowerCase();
            
            // Build JSON response with doctor availability
            StringBuilder jsonResponse = new StringBuilder();
            jsonResponse.append("{\"doctors\": [");
            
            boolean firstDoctor = true;
            for (Doctor doctor : availableDoctors) {
                if (!firstDoctor) {
                    jsonResponse.append(",");
                }
                
                // Get doctor's schedule for this day
                List<Schedule> schedules = getDoctorScheduleForDay(doctor.getId(), dayOfWeek);
                
                // Get existing appointments for this doctor on this date
                List<Appointment> existingAppointments = getExistingAppointments(doctor.getId(), selectedDate);
                
                // Generate available time slots
                List<Map<String, Object>> timeSlots = generateAvailableTimeSlots(schedules, existingAppointments);
                
                jsonResponse.append("{");
                jsonResponse.append("\"id\": ").append(doctor.getId()).append(",");
                
                // Handle potential null values
                String doctorName = doctor.getName();
                String doctorSpecialization = doctor.getSpecialization();
                
                System.out.println("Processing doctor for JSON: ID=" + doctor.getId() + 
                                 ", Original Name=" + doctorName + 
                                 ", Original Specialization=" + doctorSpecialization);
                
                if (doctorName == null) {
                    doctorName = "Unknown Doctor";
                }
                if (doctorSpecialization == null) {
                    doctorSpecialization = "General Practice";
                }
                
                System.out.println("After null check: Name=" + doctorName + 
                                 ", Specialization=" + doctorSpecialization);
                
                jsonResponse.append("\"name\": \"").append(escapeJson(doctorName)).append("\",");
                jsonResponse.append("\"specialization\": \"").append(escapeJson(doctorSpecialization)).append("\",");
                jsonResponse.append("\"timeSlots\": [");
                
                boolean firstSlot = true;
                for (Map<String, Object> slot : timeSlots) {
                    if (!firstSlot) {
                        jsonResponse.append(",");
                    }
                    jsonResponse.append("{");
                    jsonResponse.append("\"time\": \"").append(slot.get("time")).append("\",");
                    jsonResponse.append("\"display\": \"").append(slot.get("display")).append("\",");
                    jsonResponse.append("\"available\": ").append(slot.get("available"));
                    jsonResponse.append("}");
                    firstSlot = false;
                }
                
                jsonResponse.append("]}");
                firstDoctor = false;
            }
            
            jsonResponse.append("]}");
            
            System.out.println("=== FINAL JSON RESPONSE ===");
            System.out.println(jsonResponse.toString());
            System.out.println("===========================");
            
            out.write(jsonResponse.toString());
            
        } catch (Exception e) {
            e.printStackTrace();
            out.write("{\"error\": \"System error: " + e.getMessage() + "\"}");
        } finally {
            out.close();
        }
    }
    
    /**
     * Handle AJAX request to get doctors for a specific treatment (used by reschedule form)
     */
    private void handleGetDoctorsForTreatment(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();
        
        try {
            String treatmentIdStr = request.getParameter("treatment_id");
            
            if (treatmentIdStr == null) {
                out.write("{\"error\": \"Missing treatment_id parameter\"}");
                return;
            }
            
            int treatmentId = Integer.parseInt(treatmentIdStr);
            
            // Get doctors for this treatment
            List<Doctor> availableDoctors = getAvailableDoctorsForTreatment(treatmentId);
            
            // Build JSON response with doctors
            StringBuilder jsonResponse = new StringBuilder();
            jsonResponse.append("{\"doctors\": [");
            
            boolean first = true;
            for (Doctor doctor : availableDoctors) {
                if (!first) {
                    jsonResponse.append(",");
                }
                
                jsonResponse.append("{");
                jsonResponse.append("\"id\": ").append(doctor.getId()).append(",");
                
                // Handle potential null values
                String doctorName = doctor.getName();
                String doctorSpecialization = doctor.getSpecialization();
                
                if (doctorName == null) {
                    doctorName = "Unknown Doctor";
                }
                if (doctorSpecialization == null) {
                    doctorSpecialization = "General Practice";
                }
                
                jsonResponse.append("\"name\": \"").append(escapeJson(doctorName)).append("\",");
                jsonResponse.append("\"specialization\": \"").append(escapeJson(doctorSpecialization)).append("\"");
                jsonResponse.append("}");
                
                first = false;
            }
            
            jsonResponse.append("]}");
            out.write(jsonResponse.toString());
            
        } catch (NumberFormatException e) {
            out.write("{\"error\": \"Invalid treatment_id parameter\"}");
        } catch (Exception e) {
            e.printStackTrace();
            out.write("{\"error\": \"System error: " + e.getMessage() + "\"}");
        } finally {
            out.close();
        }
    }
    
    /**
     * Get doctors available for a specific treatment (by treatment-doctor relationship)
     */
    private List<Doctor> getAvailableDoctorsForTreatment(int treatmentId) {
        try {
            // First, try to use the optimized query from DoctorFacade
            try {
                List<Doctor> doctorsFromQuery = doctorFacade.findDoctorsByTreatment(treatmentId);
                if (doctorsFromQuery != null && !doctorsFromQuery.isEmpty()) {
                    System.out.println("Found " + doctorsFromQuery.size() + " doctors using direct query");
                    for (Doctor doctor : doctorsFromQuery) {
                        System.out.println("Doctor via query: ID=" + doctor.getId() + 
                                         ", Name=" + doctor.getName() + 
                                         ", Specialization=" + doctor.getSpecialization());
                    }
                    return doctorsFromQuery;
                }
            } catch (Exception e) {
                System.out.println("Direct query failed, falling back to treatment entity method: " + e.getMessage());
            }
            
            // Fallback: Get the treatment to access its associated doctors via entity relationship
            Treatment treatment = treatmentFacade.find(treatmentId);
            if (treatment == null) {
                System.out.println("Treatment not found for ID: " + treatmentId);
                return new ArrayList<>();
            }
            
            // Get doctors associated with this treatment
            Set<Doctor> doctorSet = treatment.getDoctors();
            List<Doctor> availableDoctors = new ArrayList<>();
            
            if (doctorSet != null && !doctorSet.isEmpty()) {
                availableDoctors.addAll(doctorSet);
                System.out.println("Found " + availableDoctors.size() + " doctors for treatment: " + treatment.getName());
                
                for (Doctor doctor : availableDoctors) {
                    System.out.println("Doctor: ID=" + doctor.getId() + 
                                     ", Name=" + doctor.getName() + 
                                     ", Specialization=" + doctor.getSpecialization());
                }
            } else {
                System.out.println("No doctors associated with treatment: " + treatment.getName());
                // Fallback: If no specific doctors are associated, try to match by specialization
                List<Doctor> allDoctors = doctorFacade.findAll();
                String treatmentName = treatment.getName().toLowerCase();
                
                for (Doctor doctor : allDoctors) {
                    String specialization = doctor.getSpecialization();
                    if (specialization != null) {
                        specialization = specialization.toLowerCase();
                        // Basic matching logic - can be enhanced
                        if (treatmentName.contains("dental") && specialization.contains("dental") ||
                            treatmentName.contains("cardio") && specialization.contains("cardio") ||
                            treatmentName.contains("neuro") && specialization.contains("neuro") ||
                            treatmentName.contains("ortho") && specialization.contains("ortho") ||
                            specialization.contains("general")) {
                            availableDoctors.add(doctor);
                        }
                    }
                }
                System.out.println("Fallback: Found " + availableDoctors.size() + " doctors by specialization matching");
            }
            
            return availableDoctors;
            
        } catch (Exception e) {
            System.out.println("Error getting doctors for treatment ID " + treatmentId + ": " + e.getMessage());
            e.printStackTrace();
            return new ArrayList<>();
        }
    }
    
    /**
     * Get doctor's schedule for a specific day of week
     */
    private List<Schedule> getDoctorScheduleForDay(int doctorId, String dayOfWeek) {
        System.out.println("Getting schedule for doctor ID: " + doctorId + ", day: " + dayOfWeek);
        List<Schedule> schedules = scheduleFacade.findByDoctorAndDay(doctorId, dayOfWeek);
        System.out.println("Found " + schedules.size() + " schedules");
        for (Schedule schedule : schedules) {
            System.out.println("Schedule: " + schedule.getDayOfWeek() + " " + schedule.getStartTime() + "-" + schedule.getEndTime());
        }
        return schedules;
    }
    
    /**
     * Get existing appointments for a doctor on a specific date
     */
    private List<Appointment> getExistingAppointments(int doctorId, String date) {
        return appointmentFacade.findByDoctorAndDate(doctorId, date);
    }
    
    /**
     * Generate available time slots based on doctor schedules and existing appointments
     */
    private List<Map<String, Object>> generateAvailableTimeSlots(List<Schedule> schedules, List<Appointment> existingAppointments) {
        List<Map<String, Object>> timeSlots = new ArrayList<>();
        
        for (Schedule schedule : schedules) {
            LocalTime startTime = LocalTime.parse(schedule.getStartTime().toString());
            LocalTime endTime = LocalTime.parse(schedule.getEndTime().toString());
            
            // Generate 30-minute slots
            LocalTime currentTime = startTime;
            while (currentTime.isBefore(endTime)) {
                Map<String, Object> slot = new HashMap<>();
                String timeString = currentTime.format(DateTimeFormatter.ofPattern("HH:mm"));
                String displayTime = formatTime12Hour(currentTime);
                
                // Check if this time slot is already booked
                boolean isAvailable = true;
                for (Appointment appointment : existingAppointments) {
                    if (appointment.getAppointmentTime() != null &&
                        appointment.getAppointmentTime().toString().equals(timeString + ":00")) {
                        isAvailable = false;
                        break;
                    }
                }
                
                slot.put("time", timeString);
                slot.put("display", displayTime);
                slot.put("available", isAvailable);
                timeSlots.add(slot);
                
                currentTime = currentTime.plusMinutes(30);
            }
        }
        
        return timeSlots;
    }
    
    /**
     * Format time to 12-hour format
     */
    private String formatTime12Hour(LocalTime time) {
        return time.format(DateTimeFormatter.ofPattern("h:mm a"));
    }
    
    /**
     * Escape JSON strings
     */
    private String escapeJson(String input) {
        if (input == null) return "";
        return input.replace("\"", "\\\"").replace("\\", "\\\\");
    }

    /**
     * Handle loading appointment history page with all necessary data
     */
    private void handleAppointmentHistory(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        try {
            // Check if user is logged in
            HttpSession session = request.getSession();
            Customer loggedInCustomer = (Customer) session.getAttribute("customer");

            if (loggedInCustomer == null) {
                response.sendRedirect(request.getContextPath() + "/login.jsp");
                return;
            }

            // Load all necessary data for appointment history page
            
            // 1. Load appointments for the logged-in customer only
            List<Appointment> appointmentList = appointmentFacade.findByCustomer(loggedInCustomer);
            
            // 2. Load all doctors (needed for displaying doctor information)
            List<Doctor> doctorList = doctorFacade.findAll();
            
            // 3. Load all treatments (needed for displaying treatment information)
            List<Treatment> treatmentList = treatmentFacade.findAll();
            
            // 4. Load all payments (needed for displaying payment status)
            List<Payment> paymentList = paymentFacade.findAll();
            
            // 5. Load all counter staff (needed for displaying staff information)
            List<CounterStaff> staffList = counterStaffFacade.findAll();

            // Set attributes for the JSP
            request.setAttribute("appointmentList", appointmentList);
            request.setAttribute("doctorList", doctorList);
            request.setAttribute("treatmentList", treatmentList);
            request.setAttribute("paymentList", paymentList);
            request.setAttribute("staffList", staffList);

            // Debug logging
            System.out.println("=== APPOINTMENT HISTORY DATA LOADED ===");
            System.out.println("Customer ID: " + loggedInCustomer.getId());
            System.out.println("Customer Name: " + loggedInCustomer.getName());
            System.out.println("Appointments loaded: " + (appointmentList != null ? appointmentList.size() : 0));
            System.out.println("Doctors loaded: " + (doctorList != null ? doctorList.size() : 0));
            System.out.println("Treatments loaded: " + (treatmentList != null ? treatmentList.size() : 0));
            System.out.println("Payments loaded: " + (paymentList != null ? paymentList.size() : 0));
            System.out.println("Staff loaded: " + (staffList != null ? staffList.size() : 0));
            
            if (appointmentList != null) {
                for (Appointment app : appointmentList) {
                    System.out.println("Appointment ID: " + app.getId() + 
                                     ", Status: " + app.getStatus() + 
                                     ", Date: " + app.getAppointmentDate() + 
                                     ", Doctor: " + (app.getDoctor() != null ? app.getDoctor().getName() : "None") +
                                     ", Treatment: " + (app.getTreatment() != null ? app.getTreatment().getName() : "None"));
                }
            }
            System.out.println("=======================================");

            // Forward to the appointment history JSP page
            request.getRequestDispatcher("/customer/appointment_history.jsp").forward(request, response);

        } catch (Exception e) {
            e.printStackTrace();
            System.out.println("Error loading appointment history: " + e.getMessage());
            response.sendRedirect(request.getContextPath() + "/customer/cust_homepage.jsp?error=history_load_failed");
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
            try {
                // Load all treatments for the reschedule form
                List<Treatment> treatmentList = treatmentFacade.findAll();
                request.setAttribute("treatmentList", treatmentList);

                // Load all doctors for the reschedule form
                List<Doctor> doctorList = doctorFacade.findAll();
                request.setAttribute("doctorList", doctorList);

                // Set the existing appointment data
                request.setAttribute("existingAppointment", appointment);

                // Log for debugging
                System.out.println("=== RESCHEDULE DATA LOADED ===");
                System.out.println("Appointment ID: " + appointment.getId());
                System.out.println("Current Treatment: " + (appointment.getTreatment() != null ? appointment.getTreatment().getName() : "None"));
                System.out.println("Current Doctor: " + (appointment.getDoctor() != null ? appointment.getDoctor().getName() : "None"));
                System.out.println("Current Date: " + appointment.getAppointmentDate());
                System.out.println("Current Time: " + appointment.getAppointmentTime());
                System.out.println("Status: " + appointment.getStatus());
                System.out.println("Treatments loaded: " + (treatmentList != null ? treatmentList.size() : 0));
                System.out.println("Doctors loaded: " + (doctorList != null ? doctorList.size() : 0));
                System.out.println("==============================");

            } catch (Exception e) {
                e.printStackTrace();
                System.out.println("Error loading reschedule form data: " + e.getMessage());
                response.sendRedirect("customer/appointment_history.jsp?error=data_load_failed");
                return;
            }

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

            // Debug logging before conflict check
            System.out.println("=== CHECKING FOR APPOINTMENT CONFLICTS ===");
            System.out.println("Doctor ID: " + doctorId);
            System.out.println("Appointment Date: " + appointmentDate);
            System.out.println("Appointment Time: " + appointmentTime);
            System.out.println("==========================================");

            // Check for existing appointment conflicts
            boolean hasConflict = hasAppointmentConflict(doctorId, appointmentDate, appointmentTime);
            System.out.println("Conflict check result: " + hasConflict);
            
            if (hasConflict) {
                System.out.println("REDIRECTING TO TIME CONFLICT ERROR");
                response.sendRedirect(request.getContextPath() + "/customer/appointment.jsp?error=time_conflict");
                return;
            }

            System.out.println("No conflicts - proceeding with appointment creation");

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
            response.sendRedirect(request.getContextPath() + "/AppointmentServlet?action=history&success=booked");

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
            response.sendRedirect(request.getContextPath() + "/AppointmentServlet?action=history&success=cancelled");

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
            String message = request.getParameter("customer_message"); // Fixed parameter name

            // Debug logging - can be removed later
            System.out.println("=== RESCHEDULE DEBUG ===");
            System.out.println("Appointment ID: " + appointmentIdStr);
            System.out.println("Treatment ID: " + treatmentIdStr);
            System.out.println("Doctor ID: " + doctorIdStr);
            System.out.println("Date: " + appointmentDate);
            System.out.println("Time: " + appointmentTime);
            System.out.println("Message: " + message);
            System.out.println("Original Status: " + originalStatus);

            if (appointmentIdStr == null || appointmentIdStr.trim().isEmpty()) {
                System.out.println("ERROR: Missing appointment ID");
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
                System.out.println("ERROR: Cannot reschedule appointment with status: " + currentStatus);
                response.sendRedirect("customer/appointment_history.jsp?error=cannot_reschedule");
                return;
            }

            // Validate required fields
            if (treatmentIdStr == null || treatmentIdStr.trim().isEmpty() ||
                doctorIdStr == null || doctorIdStr.trim().isEmpty() ||
                appointmentDate == null || appointmentDate.trim().isEmpty() ||
                appointmentTime == null || appointmentTime.trim().isEmpty()) {
                System.out.println("ERROR: Missing required fields for reschedule");
                response.sendRedirect("customer/appointment_reschedule.jsp?id=" + appointmentId + "&error=invalid_data");
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

            System.out.println("About to update appointment in database...");
            appointmentFacade.edit(appointment);
            System.out.println("Appointment updated successfully in database!");

            // Redirect back to appointment history with success message
            response.sendRedirect(request.getContextPath() + "/AppointmentServlet?action=history&success=rescheduled");

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

        // Get current hour to check if today is still bookable
        java.time.LocalTime currentTime = java.time.LocalTime.now();
        boolean todayBookable = currentTime.isBefore(java.time.LocalTime.of(17, 0)); // Before 5 PM
        
        // Check if date is valid for booking
        if (appointmentLocalDate.isBefore(today)) {
            return false; // Past dates not allowed
        }
        
        if (appointmentLocalDate.equals(today) && !todayBookable) {
            return false; // Today not bookable after 5 PM
        }

        // Check if date is within 7 days from today (inclusive)
        LocalDate maxBookingDate = today.plusDays(6); // 7 days total including today
        if (appointmentLocalDate.isAfter(maxBookingDate)) {
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
            // First, try to use a more specific query to reduce data transfer
            List<Appointment> doctorAppointments = null;
            
            try {
                // Try to get appointments for specific doctor and date (if such method exists)
                doctorAppointments = appointmentFacade.findByDoctorAndDate(doctorId, 
                    new SimpleDateFormat("yyyy-MM-dd").format(appointmentDate));
                System.out.println("Using specific doctor/date query - found " + 
                    (doctorAppointments != null ? doctorAppointments.size() : 0) + " appointments");
            } catch (Exception e) {
                System.out.println("Specific query not available, falling back to findAll()");
                // Fallback to getting all appointments
                List<Appointment> allAppointments = appointmentFacade.findAll();
                doctorAppointments = new ArrayList<>();
                
                if (allAppointments != null) {
                    for (Appointment app : allAppointments) {
                        if (app != null && app.getDoctor() != null && app.getDoctor().getId() == doctorId) {
                            doctorAppointments.add(app);
                        }
                    }
                }
            }
            
            // If no existing appointments for this doctor, no conflict possible
            if (doctorAppointments == null || doctorAppointments.isEmpty()) {
                System.out.println("No existing appointments for doctor ID " + doctorId + " - no conflict");
                return false;
            }
            
            System.out.println("Checking for conflicts among " + doctorAppointments.size() + 
                " appointments for doctor ID " + doctorId);

            for (Appointment appointment : doctorAppointments) {
                // Skip null appointments or appointments with null data
                if (appointment == null || appointment.getDoctor() == null || 
                    appointment.getAppointmentDate() == null || appointment.getAppointmentTime() == null) {
                    System.out.println("Skipping appointment with null data");
                    continue;
                }
                
                // Skip cancelled appointments
                if ("cancelled".equals(appointment.getStatus())) {
                    System.out.println("Skipping cancelled appointment ID: " + appointment.getId());
                    continue;
                }
                
                // Check if same date and time
                if (isSameDate(appointment.getAppointmentDate(), appointmentDate)
                        && isSameTime(appointment.getAppointmentTime(), appointmentTime)) {
                    System.out.println("CONFLICT FOUND: Same date and time");
                    System.out.println("Existing appointment ID: " + appointment.getId());
                    System.out.println("Existing date: " + appointment.getAppointmentDate());
                    System.out.println("Existing time: " + appointment.getAppointmentTime());
                    System.out.println("New date: " + appointmentDate);
                    System.out.println("New time: " + appointmentTime);
                    return true; // Conflict found
                }
            }

            System.out.println("No conflicts found - appointment can be booked");
            return false; // No conflict

        } catch (Exception e) {
            System.out.println("ERROR in hasAppointmentConflict: " + e.getMessage());
            e.printStackTrace();
            
            // For empty database or first appointment, don't assume conflict
            // Check if it's a table doesn't exist error (common with new databases)
            String errorMsg = e.getMessage();
            if (errorMsg != null) {
                String lowerErrorMsg = errorMsg.toLowerCase();
                if (lowerErrorMsg.contains("table") && (lowerErrorMsg.contains("not found") || 
                    lowerErrorMsg.contains("doesn't exist") || lowerErrorMsg.contains("does not exist"))) {
                    System.out.println("Table doesn't exist - assuming this is first appointment, no conflict");
                    return false;
                }
                if (lowerErrorMsg.contains("no data found") || lowerErrorMsg.contains("empty")) {
                    System.out.println("No data found - assuming this is first appointment, no conflict");
                    return false;
                }
            }
            
            // For any other real database errors, be conservative and assume conflict
            System.out.println("Real database error detected - assuming conflict for safety");
            return true;
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
