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
import java.util.Calendar;
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
import model.CustomerFacade;
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
import model.LeaveRequest;
import model.LeaveRequestFacade;

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
    private CustomerFacade customerFacade;
    
    @EJB
    private ScheduleFacade scheduleFacade;
    
    @EJB
    private PaymentFacade paymentFacade;
    
    @EJB
    private LeaveRequestFacade scheduleUnavailableFacade;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // Automatically update overdue appointments at the start of any GET request
        updateOverdueAppointments();

        String action = request.getParameter("action");

        // Check if user is logged in for customer actions - OPTIMIZE TO PREVENT LOOPS
        HttpSession session = request.getSession(false); // Don't create new session
        Customer loggedInCustomer = null;
        
        if (session != null) {
            loggedInCustomer = (Customer) session.getAttribute("customer");
        }

        if ("view".equals(action)) {
            // Manager view - show all appointments
            List<Appointment> appointments = appointmentFacade.findAll();
            request.setAttribute("appointments", appointments);
            request.getRequestDispatcher("manager/view_apt.jsp").forward(request, response);

        } else if ("reschedule".equals(action)) {
            // Load reschedule form
            if (loggedInCustomer == null) {
                response.sendRedirect(request.getContextPath() + "/login.jsp");
                return;
            }
            handleLoadReschedule(request, response);
        } else if ("getAvailableSlots".equals(action)) {
            // AJAX request to get available time slots for doctors on selected date
            handleGetAvailableSlots(request, response);
        } else if ("getDoctorsForTreatment".equals(action)) {
            // AJAX request to get doctors for a specific treatment (for reschedule form)
            handleGetDoctorsForTreatment(request, response);
        } else if ("history".equals(action)) {
            // Load appointment history page with data
            if (loggedInCustomer == null) {
                response.sendRedirect(request.getContextPath() + "/login.jsp");
                return;
            }
            handleAppointmentHistory(request, response);
        } else if ("manage".equals(action)) {
            // Counter staff manage appointments page
            CounterStaff loggedInStaff = (CounterStaff) session.getAttribute("staff");
            
            if (loggedInStaff == null) {
                response.sendRedirect(request.getContextPath() + "/login.jsp");
                return;
            }
            
            handleManageAppointments(request, response);
        } else if ("getAppointmentDetails".equals(action)) {
            // AJAX request to get appointment details for reschedule
            handleGetAppointmentDetails(request, response);
        } else if ("viewDetails".equals(action)) {
            // View appointment details
            handleViewAppointmentDetails(request, response);
        } else if ("getAvailableDoctors".equals(action)) {
            // Get available doctors for assignment
            handleGetAvailableDoctors(request, response);
        } else if ("checkDoctorAvailability".equals(action)) {
            // AJAX endpoint to check doctor availability for assignment
            handleCheckDoctorAvailability(request, response);
        } else if ("rescheduleStaff".equals(action)) {
            // Counter staff reschedule page
            CounterStaff loggedInStaff = (CounterStaff) session.getAttribute("staff");
            
            if (loggedInStaff == null) {
                response.sendRedirect(request.getContextPath() + "/login.jsp");
                return;
            }
            
            // Get appointment ID and load appointment data
            String appointmentIdParam = request.getParameter("appointmentId");
            if (appointmentIdParam == null || appointmentIdParam.trim().isEmpty()) {
                response.sendRedirect(request.getContextPath() + "/AppointmentServlet?action=manage&error=invalid_data");
                return;
            }
            
            try {
                int appointmentId = Integer.parseInt(appointmentIdParam);
                Appointment selectedAppointment = appointmentFacade.find(appointmentId);
                
                if (selectedAppointment == null) {
                    response.sendRedirect(request.getContextPath() + "/AppointmentServlet?action=manage&error=appointment_not_found");
                    return;
                }
                
                // Load required data for reschedule form
                request.setAttribute("doctorList", doctorFacade.findAll());
                request.setAttribute("treatmentList", treatmentFacade.findAll());
                request.setAttribute("selectedAppointment", selectedAppointment);
                
                request.getRequestDispatcher("counter_staff/staff_reschedule.jsp").forward(request, response);
                
            } catch (NumberFormatException e) {
                response.sendRedirect(request.getContextPath() + "/AppointmentServlet?action=manage&error=invalid_data");
                return;
            }
        } else if (action == null || "book".equals(action)) {
            // Show form for booking - check if user is logged in (customer or counter staff)
            CounterStaff loggedInStaff = (CounterStaff) session.getAttribute("staff");
            
            if (loggedInCustomer == null && loggedInStaff == null) {
                response.sendRedirect(request.getContextPath() + "/login.jsp");
                return;
            }
            
            request.setAttribute("doctorList", doctorFacade.findAll());
            request.setAttribute("treatmentList", treatmentFacade.findAll());
            
            // Set appropriate JSP based on who is accessing
            if (loggedInStaff != null) {
                // Counter staff accessing - need to show customer selection as well
                request.getRequestDispatcher("counter_staff/appointment_book.jsp").forward(request, response);
            } else {
                // Customer accessing
                request.getRequestDispatcher("customer/appointment.jsp").forward(request, response);
            }
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
            Date appointmentDate = new SimpleDateFormat("yyyy-MM-dd").parse(selectedDate);
            
            // Get treatment to find related doctors by specialization
            Treatment treatment = treatmentFacade.find(treatmentId);
            if (treatment == null) {
                out.write("{\"error\": \"Treatment not found\"}");
                return;
            }
            
            // Get doctors for this treatment
            List<Doctor> availableDoctors = getAvailableDoctorsForTreatment(treatmentId);
           
            // Convert date string to determine day of week
            LocalDate date = LocalDate.parse(selectedDate);
            String dayOfWeek = date.getDayOfWeek().toString(); // Monday, Tuesday, etc
            dayOfWeek = dayOfWeek.substring(0, 1).toUpperCase() + dayOfWeek.substring(1).toLowerCase();
            
            // Build JSON response with comprehensive availability checking
            StringBuilder jsonResponse = new StringBuilder();
            jsonResponse.append("{\"doctors\": [");
            
            boolean firstDoctor = true;
            for (Doctor doctor : availableDoctors) {
                if (!firstDoctor) {
                    jsonResponse.append(",");
                }
                
                // Get doctor's schedule for this day
                List<Schedule> schedules = getDoctorScheduleForDay(doctor.getId(), dayOfWeek);
                
                // Generate comprehensive time slots with cross-table validation
                List<Map<String, Object>> timeSlots = generateComprehensiveTimeSlots(doctor.getId(), appointmentDate, schedules);
                
                jsonResponse.append("{");
                jsonResponse.append("\"id\": ").append(doctor.getId()).append(",");
                
                String doctorName = doctor.getName();
                String doctorSpecialization = doctor.getSpecialization();
                
                if (doctorName == null) doctorName = "Unknown Doctor";
                if (doctorSpecialization == null) doctorSpecialization = "General Practice";
                
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
                    if (slot.get("reason") != null) {
                        jsonResponse.append(",\"reason\": \"").append(slot.get("reason")).append("\"");
                    }
                    jsonResponse.append("}");
                    firstSlot = false;
                }
                
                jsonResponse.append("]}");
                firstDoctor = false;
            }
            
            jsonResponse.append("]}");
            
            System.out.println("=== COMPREHENSIVE AVAILABILITY RESPONSE ===");
            System.out.println("Treatment: " + treatment.getName());
            System.out.println("Date: " + selectedDate);
            System.out.println("Day: " + dayOfWeek);
            System.out.println("Doctors processed: " + availableDoctors.size());
            System.out.println("===========================================");
            
            out.write(jsonResponse.toString());
            
        } catch (Exception e) {
            e.printStackTrace();
            out.write("{\"error\": \"System error: " + e.getMessage() + "\"}");
        } finally {
            out.close();
        }
    }
    
    /**
     * Generate comprehensive time slots with cross-table validation
 Step 1: Check LeaveRequest - doctor is off on specific dates
 Step 2: Get the doctor's working hours on that weekday (Schedule)
 Step 3: Check existing bookings (Appointment)
     */
    private List<Map<String, Object>> generateComprehensiveTimeSlots(int doctorId, Date appointmentDate, List<Schedule> schedules) {
        List<Map<String, Object>> timeSlots = new ArrayList<>();
        
        if (schedules == null || schedules.isEmpty()) {
            System.out.println("No schedules found for doctor " + doctorId + " - not working this day");
            return timeSlots;
        }
        
        // Get existing appointments for this doctor on this date
        List<Appointment> existingAppointments = getExistingAppointments(doctorId, 
            new SimpleDateFormat("yyyy-MM-dd").format(appointmentDate));
        
        for (Schedule schedule : schedules) {
            try {
                LocalTime startTime = LocalTime.parse(schedule.getStartTime().toString());
                LocalTime endTime = LocalTime.parse(schedule.getEndTime().toString());
                
                System.out.println("Generating slots for doctor " + doctorId + ": " + startTime + " to " + endTime);
                
                // Generate 30-minute slots
                LocalTime currentTime = startTime;
                while (currentTime.isBefore(endTime)) {
                    String timeString = currentTime.format(DateTimeFormatter.ofPattern("HH:mm"));
                    Time slotTime = new Time(currentTime.getHour(), currentTime.getMinute(), 0);
                    
                    // Use comprehensive availability check
                    AvailabilityResult availabilityResult = checkComprehensiveAvailability(doctorId, appointmentDate, slotTime, null);
                    
                    Map<String, Object> slot = new HashMap<>();
                    slot.put("time", timeString);
                    slot.put("display", formatTime12Hour(currentTime));
                    slot.put("available", availabilityResult.isAvailable());
                    
                    if (!availabilityResult.isAvailable()) {
                        slot.put("reason", availabilityResult.getReason());
                    }
                    
                    timeSlots.add(slot);
                    currentTime = currentTime.plusMinutes(30);
                }
            } catch (Exception e) {
                System.out.println("Error processing schedule for doctor " + doctorId + ": " + e.getMessage());
                e.printStackTrace();
            }
        }
        
        System.out.println("Generated " + timeSlots.size() + " time slots for doctor " + doctorId);
        return timeSlots;
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
     * Generate available time slots based on doctor schedules, unavailabilities, and existing appointments
     * This method implements comprehensive cross-table validation:
     * 1. Check LeaveRequest - doctor is off on specific dates
 2. Check Schedule - doctor's working hours on that weekday
 3. Check Appointment - already booked slots by other customers
     */
    private List<Map<String, Object>> generateAvailableTimeSlots(List<Schedule> schedules, List<Appointment> existingAppointments) {
        List<Map<String, Object>> timeSlots = new ArrayList<>();
        
        if (schedules == null || schedules.isEmpty()) {
            System.out.println("No schedules found - doctor may not work on this day");
            return timeSlots;
        }
        
        for (Schedule schedule : schedules) {
            try {
                LocalTime startTime = LocalTime.parse(schedule.getStartTime().toString());
                LocalTime endTime = LocalTime.parse(schedule.getEndTime().toString());
                
                System.out.println("Processing schedule: " + startTime + " to " + endTime);
                
                // Generate 30-minute slots
                LocalTime currentTime = startTime;
                while (currentTime.isBefore(endTime)) {
                    Map<String, Object> slot = new HashMap<>();
                    String timeString = currentTime.format(DateTimeFormatter.ofPattern("HH:mm"));
                    String displayTime = formatTime12Hour(currentTime);
                    
                    // Check if this time slot is already booked (existing appointments)
                    boolean isBookedByAppointment = false;
                    for (Appointment appointment : existingAppointments) {
                        if (appointment.getAppointmentTime() != null &&
                            appointment.getAppointmentTime().toString().equals(timeString + ":00")) {
                            // Skip cancelled appointments - they don't block slots
                            if (!"cancelled".equals(appointment.getStatus())) {
                                isBookedByAppointment = true;
                                System.out.println("Slot " + timeString + " blocked by existing appointment ID: " + appointment.getId());
                                break;
                            }
                        }
                    }
                    
                    slot.put("time", timeString);
                    slot.put("display", displayTime);
                    slot.put("available", !isBookedByAppointment);
                    
                    if (isBookedByAppointment) {
                        slot.put("reason", "Already booked");
                    }
                    
                    timeSlots.add(slot);
                    currentTime = currentTime.plusMinutes(30);
                }
            } catch (Exception e) {
                System.out.println("Error processing schedule: " + e.getMessage());
                e.printStackTrace();
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
    private String escapeJson(String str) {
    if (str == null) return "";
    return str.replace("\\", "\\\\")
              .replace("\"", "\\\"")
              .replace("\n", "\\n")
              .replace("\r", "\\r")
              .replace("\t", "\\t");
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

            // Automatically update overdue appointments before loading data
            updateOverdueAppointments();

            // Load all necessary data for appointment history page
            
            // 1. Load appointments for the logged-in customer only
            List<Appointment> appointmentList = appointmentFacade.findByCustomer(loggedInCustomer);
            
            // 2. Check if status filter is requested
            String statusFilter = request.getParameter("status");
            if (statusFilter != null && !statusFilter.trim().isEmpty()) {
                String filterStatus = statusFilter.trim().toLowerCase();
                
                System.out.println("Filtering appointments by status: " + filterStatus);
                
                // Handle "all" status - don't filter, show everything
                if (!"all".equals(filterStatus)) {
                    List<Appointment> filteredAppointments = new ArrayList<>();
                    
                    for (Appointment apt : appointmentList) {
                        if (apt.getStatus() != null) {
                            String aptStatus = apt.getStatus().trim().toLowerCase();
                            
                            // Handle specific filtering cases with CASE-INSENSITIVE comparison
                            if ("overdue".equals(filterStatus) && "overdue".equals(aptStatus)) {
                                filteredAppointments.add(apt);
                            } else if ("reschedule".equals(filterStatus) && "reschedule".equals(aptStatus)) {
                                filteredAppointments.add(apt);
                            } else if ("approved".equals(filterStatus) && ("approved".equals(aptStatus) || "confirmed".equals(aptStatus))) {
                                filteredAppointments.add(apt);
                            } else if ("completed".equals(filterStatus) && "completed".equals(aptStatus)) {
                                filteredAppointments.add(apt);
                            } else if ("cancelled".equals(filterStatus) && "cancelled".equals(aptStatus)) {
                                filteredAppointments.add(apt);
                            } else if ("pending".equals(filterStatus) && "pending".equals(aptStatus)) {
                                filteredAppointments.add(apt);
                            }
                        }
                    }
                    
                    appointmentList = filteredAppointments;
                    System.out.println("Filtered to " + appointmentList.size() + " appointments with status: " + filterStatus);
                } else {
                    System.out.println("Status filter is 'all' - showing all " + appointmentList.size() + " appointments");
                }
            } else {
                // No status parameter - treat as "all" appointments
                System.out.println("No status filter provided - showing all " + appointmentList.size() + " appointments");
            }
            
            // 3. Load all doctors (needed for displaying doctor information)
            List<Doctor> doctorList = doctorFacade.findAll();
            
            // 4. Load all treatments (needed for displaying treatment information)
            List<Treatment> treatmentList = treatmentFacade.findAll();
            
            // 5. Load all payments (needed for displaying payment status)
            List<Payment> paymentList = paymentFacade.findAll();
            
            // 6. Load all counter staff (needed for displaying staff information)
            List<CounterStaff> staffList = counterStaffFacade.findAll();

            // Set attributes for the JSP
            request.setAttribute("appointmentList", appointmentList);
            request.setAttribute("doctorList", doctorList);
            request.setAttribute("treatmentList", treatmentList);
            request.setAttribute("paymentList", paymentList);
            request.setAttribute("staffList", staffList);
            
            // Set status filter for JSP display (CRITICAL - pass as parameter too!)
            if (statusFilter != null && !statusFilter.trim().isEmpty()) {
                request.setAttribute("statusFilter", statusFilter.trim().toLowerCase());
                // ALSO set as parameter for JSP compatibility
                request.setAttribute("javax.servlet.forward.query_string", "status=" + statusFilter.trim().toLowerCase());
            }

            // Debug logging with enhanced appointment details
            System.out.println("=== APPOINTMENT HISTORY DATA LOADED ===");
            System.out.println("Customer ID: " + loggedInCustomer.getId());
            System.out.println("Customer Name: " + loggedInCustomer.getName());
            System.out.println("Status Filter: " + (statusFilter != null ? statusFilter : "none"));
            System.out.println("Appointments loaded: " + (appointmentList != null ? appointmentList.size() : 0));
            System.out.println("Doctors loaded: " + (doctorList != null ? doctorList.size() : 0));
            System.out.println("Treatments loaded: " + (treatmentList != null ? treatmentList.size() : 0));
            System.out.println("Payments loaded: " + (paymentList != null ? paymentList.size() : 0));
            System.out.println("Staff loaded: " + (staffList != null ? staffList.size() : 0));
            
            if (appointmentList != null) {
                System.out.println("=== DETAILED APPOINTMENT LIST ===");
                for (Appointment app : appointmentList) {
                    System.out.println("Appointment ID: " + app.getId() + 
                                     ", Status: '" + app.getStatus() + "'" + 
                                     ", Date: " + app.getAppointmentDate() + 
                                     ", Doctor: " + (app.getDoctor() != null ? app.getDoctor().getName() : "None") +
                                     ", Treatment: " + (app.getTreatment() != null ? app.getTreatment().getName() : "None") +
                                     ", Customer: " + (app.getCustomer() != null ? app.getCustomer().getName() : "None"));
                }
                System.out.println("=== END APPOINTMENT LIST ===");
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

            // Validate that appointment can be rescheduled (only pending, approved, overdue, or reschedule required)
            String status = appointment.getStatus();
            if (!"pending".equals(status) && !"approved".equals(status) && !"overdue".equals(status) && !"reschedule".equals(status)) {
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
                System.out.println("Staff Message: " + (appointment.getStaffMessage() != null ? appointment.getStaffMessage() : "None"));
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
        } else if ("assignDoctor".equals(action)) {
            handleAssignDoctor(request, response);
        } else if ("checkDoctorAvailability".equals(action)) {
            checkDoctorAvailability(request, response);
        } else if ("updateStatus".equals(action)) {
            handleUpdateAppointmentStatus(request, response);
        } else if ("requireReschedule".equals(action)) {
            handleRequireReschedule(request, response);
        } else {
            // Default redirect based on user type
            HttpSession session = request.getSession();
            CounterStaff loggedInStaff = (CounterStaff) session.getAttribute("staff");
            
            if (loggedInStaff != null) {
                response.sendRedirect(request.getContextPath() + "/counter_staff/counter_homepage.jsp");
            } else {
                response.sendRedirect(request.getContextPath() + "/customer/appointment.jsp");
            }
        }
    }

    /**
     * Handle appointment booking request - supports both customer and counter staff booking
     */
    private void handleBookAppointment(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // Declare variables that need to be available in catch blocks
        boolean isStaffBooking = false;
        
        try {
            // Determine booking source and get customer
            HttpSession session = request.getSession();
            Customer targetCustomer = null;
            CounterStaff loggedInStaff = null;
            Customer loggedInCustomer = null;
            
            // Check if this is a counter staff booking
            loggedInStaff = (CounterStaff) session.getAttribute("staff");
            loggedInCustomer = (Customer) session.getAttribute("customer");
            
            String customerIdStr = request.getParameter("customer_id");
            
            if (loggedInStaff != null) {
                // Counter staff is booking for a customer
                isStaffBooking = true;
                
                if (customerIdStr == null || customerIdStr.trim().isEmpty()) {
                    response.sendRedirect(request.getContextPath() + "/AppointmentServlet?action=book&error=missing_customer");
                    return;
                }
                
                try {
                    int customerId = Integer.parseInt(customerIdStr);
                    targetCustomer = customerFacade.findById(customerId);
                    
                    if (targetCustomer == null) {
                        response.sendRedirect(request.getContextPath() + "/AppointmentServlet?action=book&error=customer_not_found");
                        return;
                    }
                } catch (NumberFormatException e) {
                    response.sendRedirect(request.getContextPath() + "/AppointmentServlet?action=book&error=invalid_customer_id");
                    return;
                }
                
            } else if (loggedInCustomer != null) {
                // Customer is booking for themselves
                isStaffBooking = false;
                targetCustomer = loggedInCustomer;
                
            } else {
                // No valid session found
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
                String redirectUrl = isStaffBooking ? 
                    request.getContextPath() + "/AppointmentServlet?action=book&error=" + validation.getErrorCode() :
                    request.getContextPath() + "/customer/appointment.jsp?error=" + validation.getErrorCode();
                response.sendRedirect(redirectUrl);
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
                String redirectUrl = isStaffBooking ? 
                    request.getContextPath() + "/AppointmentServlet?action=book&error=invalid_selection" :
                    request.getContextPath() + "/customer/appointment.jsp?error=invalid_selection";
                response.sendRedirect(redirectUrl);
                return;
            }

            // Validate appointment date (must be future date, weekday, within one week)
            if (!isValidAppointmentDate(appointmentDate)) {
                String redirectUrl = isStaffBooking ? 
                    request.getContextPath() + "/AppointmentServlet?action=book&error=invalid_date" :
                    request.getContextPath() + "/customer/appointment.jsp?error=invalid_date";
                response.sendRedirect(redirectUrl);
                return;
            }

            // Validate appointment time (9 AM - 5 PM, 30-minute slots)
            if (!isValidAppointmentTime(appointmentTime)) {
                String redirectUrl = isStaffBooking ? 
                    request.getContextPath() + "/AppointmentServlet?action=book&error=invalid_time" :
                    request.getContextPath() + "/customer/appointment.jsp?error=invalid_time";
                response.sendRedirect(redirectUrl);
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
                String redirectUrl = isStaffBooking ? 
                    request.getContextPath() + "/AppointmentServlet?action=book&error=time_conflict" :
                    request.getContextPath() + "/customer/appointment.jsp?error=time_conflict";
                response.sendRedirect(redirectUrl);
                return;
            }

            System.out.println("No conflicts - proceeding with appointment creation");

            // Create new appointment
            Appointment newAppointment = new Appointment();
            newAppointment.setCustomer(targetCustomer);
            newAppointment.setDoctor(doctor);
            newAppointment.setTreatment(treatment);
            newAppointment.setCounterStaff(isStaffBooking ? loggedInStaff : null);
            newAppointment.setAppointmentDate(appointmentDate);
            newAppointment.setAppointmentTime(appointmentTime);
            newAppointment.setCustMessage(customerMessage != null ? customerMessage.trim() : "");
            
            // Set status based on who is booking
            // All bookings start as "pending" so any counter staff can accept and assign a doctor
            if (isStaffBooking) {
                newAppointment.setStatus("pending"); // Counter staff bookings still need doctor assignment by any staff
            } else {
                newAppointment.setStatus("pending"); // Customer bookings need approval
            }
            
            newAppointment.setDocMessage(null); // Will be set after consultation

            // Save appointment
            appointmentFacade.create(newAppointment);

            // Log successful booking
            System.out.println("=== APPOINTMENT BOOKED SUCCESSFULLY ===");
            System.out.println("Booked by: " + (isStaffBooking ? "Counter Staff (" + loggedInStaff.getName() + ")" : "Customer"));
            System.out.println("Customer: " + targetCustomer.getName());
            System.out.println("Doctor: " + doctor.getName());
            System.out.println("Treatment: " + treatment.getName());
            System.out.println("Date: " + appointmentDate);
            System.out.println("Time: " + appointmentTime);
            System.out.println("Status: " + newAppointment.getStatus());
            System.out.println("======================================");

            // Redirect based on who made the booking
            if (isStaffBooking) {
                response.sendRedirect(request.getContextPath() + "/AppointmentServlet?action=book&success=appointment_booked");
            } else {
                response.sendRedirect(request.getContextPath() + "/AppointmentServlet?action=history&status=pending&success=booked");
            }

        } catch (NumberFormatException e) {
            // Determine redirect URL based on booking source
            String redirectUrl = isStaffBooking ? 
                request.getContextPath() + "/AppointmentServlet?action=book&error=invalid_data" :
                request.getContextPath() + "/customer/appointment.jsp?error=invalid_data";
            response.sendRedirect(redirectUrl);
        } catch (ParseException e) {
            String redirectUrl = isStaffBooking ? 
                request.getContextPath() + "/AppointmentServlet?action=book&error=invalid_datetime" :
                request.getContextPath() + "/customer/appointment.jsp?error=invalid_datetime";
            response.sendRedirect(redirectUrl);
        } catch (Exception e) {
            e.printStackTrace();
            String redirectUrl = isStaffBooking ? 
                request.getContextPath() + "/AppointmentServlet?action=book&error=booking_failed" :
                request.getContextPath() + "/customer/appointment.jsp?error=booking_failed";
            response.sendRedirect(redirectUrl);
        }
    }

    private void handleCancelAppointment(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        try {
            // Determine user type
            HttpSession session = request.getSession();
            CounterStaff loggedInStaff = (CounterStaff) session.getAttribute("staff");
            Customer loggedInCustomer = (Customer) session.getAttribute("customer");
            boolean isStaffOperation = loggedInStaff != null;
            
            String appointmentIdStr = request.getParameter("appointmentId");
            String currentStatus = request.getParameter("currentStatus");
            String cancellationReason = request.getParameter("cancellation_reason");

            if (appointmentIdStr == null || appointmentIdStr.trim().isEmpty()) {
                String redirectUrl = isStaffOperation ? 
                    "counter_staff/counter_homepage.jsp?error=invalid_id" :
                    "customer/appointment_history.jsp?error=invalid_id";
                response.sendRedirect(redirectUrl);
                return;
            }

            int appointmentId = Integer.parseInt(appointmentIdStr);

            // Find the appointment
            Appointment appointment = appointmentFacade.find(appointmentId);
            if (appointment == null) {
                String redirectUrl = isStaffOperation ? 
                    "counter_staff/counter_homepage.jsp?error=not_found" :
                    "customer/appointment_history.jsp?error=not_found";
                response.sendRedirect(redirectUrl);
                return;
            }

            // Validate permissions
            if (!isStaffOperation && loggedInCustomer != null) {
                // Customer can only cancel their own appointments
                if (appointment.getCustomer() == null || appointment.getCustomer().getId() != loggedInCustomer.getId()) {
                    response.sendRedirect("customer/appointment_history.jsp?error=unauthorized");
                    return;
                }
            }

            // Validate that appointment can be cancelled
            String status = appointment.getStatus();
            if (!"pending".equals(status) && !"approved".equals(status) && !"overdue".equals(status) && !"reschedule".equals(status)) {
                String redirectUrl = isStaffOperation ? 
                    "counter_staff/counter_homepage.jsp?error=cannot_cancel" :
                    "customer/appointment_history.jsp?error=cannot_cancel";
                response.sendRedirect(redirectUrl);
                return;
            }

            // Update appointment status to cancelled
            appointment.setStatus("cancelled");
            
            // Set staff message if cancelling
            String staffMessage = request.getParameter("staffMessage");
            if (isStaffOperation && staffMessage != null && !staffMessage.trim().isEmpty()) {
                appointment.setStaffMessage(staffMessage.trim());
                appointment.setCounterStaff(loggedInStaff);
            } else if (cancellationReason != null && !cancellationReason.trim().isEmpty()) {
                appointment.setStaffMessage(cancellationReason.trim());
            }
            
            appointmentFacade.edit(appointment);

            // Redirect based on user type
            if (isStaffOperation) {
                response.sendRedirect(request.getContextPath() + "/AppointmentServlet?action=manage&success=appointment_cancelled");
            } else {
                response.sendRedirect(request.getContextPath() + "/AppointmentServlet?action=history&success=cancelled");
            }

        } catch (NumberFormatException e) {
            HttpSession session = request.getSession();
            CounterStaff loggedInStaff = (CounterStaff) session.getAttribute("staff");
            String redirectUrl = loggedInStaff != null ? 
                "counter_staff/counter_homepage.jsp?error=invalid_id" :
                "customer/appointment_history.jsp?error=invalid_id";
            response.sendRedirect(redirectUrl);
        } catch (Exception e) {
            e.printStackTrace();
            HttpSession session = request.getSession();
            CounterStaff loggedInStaff = (CounterStaff) session.getAttribute("staff");
            String redirectUrl = loggedInStaff != null ? 
                "counter_staff/counter_homepage.jsp?error=system_error" :
                "customer/appointment_history.jsp?error=system_error";
            response.sendRedirect(redirectUrl);
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
            String message = request.getParameter("customer_message");

            // Enhanced debug logging
            System.out.println("=== RESCHEDULE APPOINTMENT DEBUG ===");
            System.out.println("Appointment ID parameter: " + appointmentIdStr);
            System.out.println("Original Status parameter: " + originalStatus);
            System.out.println("Treatment ID parameter: " + treatmentIdStr);
            System.out.println("Doctor ID parameter: " + doctorIdStr);
            System.out.println("Date parameter: " + appointmentDate);
            System.out.println("Time parameter: " + appointmentTime);
            System.out.println("Message parameter: " + message);

            // Validate appointment ID first
            if (appointmentIdStr == null || appointmentIdStr.trim().isEmpty()) {
                System.out.println("ERROR: Missing appointment ID parameter");
                response.sendRedirect("customer/appointment_reschedule.jsp?error=invalid_id");
                return;
            }

            int appointmentId;
            try {
                appointmentId = Integer.parseInt(appointmentIdStr.trim());
                System.out.println("Parsed appointment ID: " + appointmentId);
            } catch (NumberFormatException e) {
                System.out.println("ERROR: Invalid appointment ID format: " + appointmentIdStr);
                response.sendRedirect("customer/appointment_reschedule.jsp?error=invalid_id");
                return;
            }

            // Find the existing appointment
            System.out.println("Searching for appointment with ID: " + appointmentId);
            Appointment appointment = appointmentFacade.find(appointmentId);
            
            if (appointment == null) {
                System.out.println("ERROR: Appointment not found with ID: " + appointmentId);
                response.sendRedirect("customer/appointment_history.jsp?error=not_found");
                return;
            }

            System.out.println("Found existing appointment:");
            System.out.println("  - ID: " + appointment.getId());
            System.out.println("  - Current Status: " + appointment.getStatus());
            System.out.println("  - Customer ID: " + (appointment.getCustomer() != null ? appointment.getCustomer().getId() : "null"));
            System.out.println("  - Current Treatment: " + (appointment.getTreatment() != null ? appointment.getTreatment().getName() : "null"));
            System.out.println("  - Current Doctor: " + (appointment.getDoctor() != null ? appointment.getDoctor().getName() : "null"));
            System.out.println("  - Current Date: " + appointment.getAppointmentDate());
            System.out.println("  - Current Time: " + appointment.getAppointmentTime());

            // Validate appointment status can be rescheduled
            String currentStatus = appointment.getStatus();
            if (!"pending".equals(currentStatus) && !"approved".equals(currentStatus) && 
                !"overdue".equals(currentStatus) && !"reschedule".equals(currentStatus)) {
                System.out.println("ERROR: Cannot reschedule appointment with status: " + currentStatus);
                response.sendRedirect("customer/appointment_history.jsp?error=cannot_reschedule");
                return;
            }

            // Validate user ownership - check for either customer or staff
            HttpSession session = request.getSession();
            Customer loggedInCustomer = (Customer) session.getAttribute("customer");
            CounterStaff loggedInStaff = (CounterStaff) session.getAttribute("staff");
            boolean isStaffReschedule = (loggedInStaff != null);
            
            if (loggedInCustomer == null && loggedInStaff == null) {
                System.out.println("ERROR: No logged in user found");
                response.sendRedirect(request.getContextPath() + "/login.jsp");
                return;
            }
            
            // For customer reschedule, validate appointment ownership
            if (!isStaffReschedule) {
                if (appointment.getCustomer() == null || appointment.getCustomer().getId() != loggedInCustomer.getId()) {
                    System.out.println("ERROR: Appointment does not belong to logged in customer");
                    System.out.println("  - Appointment customer ID: " + (appointment.getCustomer() != null ? appointment.getCustomer().getId() : "null"));
                    System.out.println("  - Logged in customer ID: " + loggedInCustomer.getId());
                    response.sendRedirect("customer/appointment_history.jsp?error=unauthorized");
                    return;
                }
            } else {
                System.out.println("Staff reschedule detected - staff can reschedule any appointment");
            }

            // Validate required fields
            if (treatmentIdStr == null || treatmentIdStr.trim().isEmpty() ||
                doctorIdStr == null || doctorIdStr.trim().isEmpty() ||
                appointmentDate == null || appointmentDate.trim().isEmpty() ||
                appointmentTime == null || appointmentTime.trim().isEmpty()) {
                System.out.println("ERROR: Missing required fields for reschedule");
                System.out.println("  - Treatment ID: " + treatmentIdStr);
                System.out.println("  - Doctor ID: " + doctorIdStr);
                System.out.println("  - Date: " + appointmentDate);
                System.out.println("  - Time: " + appointmentTime);
                response.sendRedirect("customer/appointment_reschedule.jsp?id=" + appointmentId + "&error=invalid_data");
                return;
            }

            // Comprehensive availability check for both staff and customer
            int doctorId = Integer.parseInt(doctorIdStr.trim());
            Date newDate = new SimpleDateFormat("yyyy-MM-dd").parse(appointmentDate.trim());
            Time newTime = new Time(new SimpleDateFormat("HH:mm").parse(appointmentTime.trim()).getTime());
            AvailabilityResult availability = checkComprehensiveAvailability(
                doctorId,
                newDate,
                newTime,
                appointmentId
            );
            if (!availability.isAvailable()) {
                System.out.println("ERROR: Time conflict detected for reschedule: " + availability.getReason());
                if (isStaffReschedule) {
                    request.setAttribute("error", availability.getErrorCode());
                    request.setAttribute("errorMessage", availability.getReason());
                    request.getRequestDispatcher("/counter_staff/reschedule_appointment.jsp").forward(request, response);
                } else {
                    response.sendRedirect("customer/appointment_reschedule.jsp?id=" + appointmentId + "&error=" + availability.getErrorCode());
                }
                return;
            }

            System.out.println("=== UPDATING APPOINTMENT FIELDS ===");
            
            // Update treatment
            int treatmentId = Integer.parseInt(treatmentIdStr.trim());
            Treatment treatment = treatmentFacade.find(treatmentId);
            if (treatment != null) {
                System.out.println("Updating treatment from '" + 
                    (appointment.getTreatment() != null ? appointment.getTreatment().getName() : "null") + 
                    "' to '" + treatment.getName() + "'");
                appointment.setTreatment(treatment);
            } else {
                System.out.println("ERROR: Treatment not found with ID: " + treatmentId);
                response.sendRedirect("customer/appointment_reschedule.jsp?id=" + appointmentId + "&error=invalid_treatment");
                return;
            }

            // Update doctor
            Doctor doctor = doctorFacade.find(doctorId);
            if (doctor != null) {
                System.out.println("Updating doctor from '" + 
                    (appointment.getDoctor() != null ? appointment.getDoctor().getName() : "null") + 
                    "' to '" + doctor.getName() + "'");
                appointment.setDoctor(doctor);
            } else {
                System.out.println("ERROR: Doctor not found with ID: " + doctorId);
                response.sendRedirect("customer/appointment_reschedule.jsp?id=" + appointmentId + "&error=invalid_doctor");
                return;
            }

            // Update date and time
            System.out.println("Updating date from '" + appointment.getAppointmentDate() + "' to '" + newDate + "'");
            System.out.println("Updating time from '" + appointment.getAppointmentTime() + "' to '" + newTime + "'");
            appointment.setAppointmentDate(newDate);
            appointment.setAppointmentTime(newTime);

            // Update message based on user type
            if (isStaffReschedule) {
                String staffMessage = request.getParameter("staff_message");
                appointment.setStaffMessage(staffMessage != null ? staffMessage.trim() : "Appointment rescheduled by staff");
                appointment.setCounterStaff(loggedInStaff);
                System.out.println("Staff reschedule - updated staff message and assigned staff");
            } else {
                String oldMessage = appointment.getCustMessage();
                appointment.setCustMessage(message != null ? message.trim() : "");
                System.out.println("Customer reschedule - updating message from '" + oldMessage + "' to '" + appointment.getCustMessage() + "'");
            }

            // Set status based on original status
            String newStatus = "pending"; // Always set to pending for new approval
            System.out.println("Updating status from '" + appointment.getStatus() + "' to '" + newStatus + "'");
            appointment.setStatus(newStatus);

            // Clear doctor message for fresh approval process
            appointment.setDocMessage(null);
            System.out.println("Cleared doctor message for fresh approval");

            // Clear staffId automatically for all reschedules
            appointment.setCounterStaff(null);
            System.out.println("Staff ID cleared - will display 'Not assigned' in frontend");

            System.out.println("=== SAVING TO DATABASE ===");
            System.out.println("Appointment ID being updated: " + appointment.getId());
            
            try {
                // Use merge instead of edit to ensure the entity is properly updated
                appointmentFacade.edit(appointment);
                System.out.println("✓ Appointment successfully updated in database!");
                
                // Verify the update by re-fetching the appointment
                Appointment updatedAppointment = appointmentFacade.find(appointmentId);
                if (updatedAppointment != null) {
                    System.out.println("=== VERIFICATION: Updated appointment details ===");
                    System.out.println("  - ID: " + updatedAppointment.getId());
                    System.out.println("  - Status: " + updatedAppointment.getStatus());
                    System.out.println("  - Treatment: " + (updatedAppointment.getTreatment() != null ? updatedAppointment.getTreatment().getName() : "null"));
                    System.out.println("  - Doctor: " + (updatedAppointment.getDoctor() != null ? updatedAppointment.getDoctor().getName() : "null"));
                    System.out.println("  - Date: " + updatedAppointment.getAppointmentDate());
                    System.out.println("  - Time: " + updatedAppointment.getAppointmentTime());
                    System.out.println("  - Message: " + updatedAppointment.getCustMessage());
                } else {
                    System.out.println("WARNING: Could not re-fetch appointment for verification");
                }
                
            } catch (Exception dbException) {
                System.out.println("ERROR: Database update failed!");
                dbException.printStackTrace();
                response.sendRedirect("customer/appointment_reschedule.jsp?id=" + appointmentId + "&error=database_error");
                return;
            }

            System.out.println("=== RESCHEDULE COMPLETED SUCCESSFULLY ===");
            
            // Redirect based on user type
            if (isStaffReschedule) {
                response.sendRedirect(request.getContextPath() + "/AppointmentServlet?action=manage&success=appointment_rescheduled");
            } else {
                response.sendRedirect(request.getContextPath() + "/AppointmentServlet?action=history&success=rescheduled");
            }

        } catch (NumberFormatException e) {
            System.out.println("ERROR: Number format exception in reschedule");
            e.printStackTrace();
            response.sendRedirect("customer/appointment_reschedule.jsp?error=invalid_data");
        } catch (ParseException e) {
            System.out.println("ERROR: Date/time parse exception in reschedule");
            e.printStackTrace();
            response.sendRedirect("customer/appointment_reschedule.jsp?error=invalid_datetime");
        } catch (Exception e) {
            System.out.println("ERROR: General exception in reschedule");
            e.printStackTrace();
            response.sendRedirect("customer/appointment_reschedule.jsp?error=system_error");
        }
    }

     /**
     * Check if the doctor is available for the appointment date
     */
private void checkDoctorAvailability(HttpServletRequest request, HttpServletResponse response) 
        throws ServletException, IOException {

    try {
        String doctorIdStr = request.getParameter("doctorId");
        String appointmentDateStr = request.getParameter("appointmentDate");
        String appointmentTimeStr = request.getParameter("appointmentTime");

        if (doctorIdStr == null || doctorIdStr.trim().isEmpty() ||
            appointmentDateStr == null || appointmentDateStr.trim().isEmpty() ||
            appointmentTimeStr == null || appointmentTimeStr.trim().isEmpty()) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            return;
        }

        int doctorId = Integer.parseInt(doctorIdStr);
        Date appointmentDate = new SimpleDateFormat("yyyy-MM-dd").parse(appointmentDateStr);
        Time appointmentTime = Time.valueOf(appointmentTimeStr);

        // Check doctor availability
        AvailabilityResult availability = checkComprehensiveAvailability(
            doctorId,
            appointmentDate,
            appointmentTime,
            null
        );

        // Construct JSON manually
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        String json = String.format(
            "{ \"available\": %s, \"errorCode\": \"%s\", \"reason\": \"%s\" }",
            availability.isAvailable(),
            escapeJson(availability.getErrorCode()),
            escapeJson(availability.getReason())
        );

        response.getWriter().write(json);

    } catch (NumberFormatException | ParseException e) {
        response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
    } catch (Exception e) {
        e.printStackTrace();
        response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
    }
}

    /**
     * Handle doctor assignment to appointment - Counter staff only
     */
    private void handleAssignDoctor(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        try {
            // Verify counter staff authorization
            HttpSession session = request.getSession();
            CounterStaff loggedInStaff = (CounterStaff) session.getAttribute("staff");
            
            if (loggedInStaff == null) {
                response.sendRedirect(request.getContextPath() + "/login.jsp");
                return;
            }
            
            String appointmentIdStr = request.getParameter("appointmentId");
            String doctorIdStr = request.getParameter("doctorId");
            String staffMessage = request.getParameter("staff_message");
            
            if (appointmentIdStr == null || appointmentIdStr.trim().isEmpty() ||
                doctorIdStr == null || doctorIdStr.trim().isEmpty()) {
                response.sendRedirect(request.getContextPath() + "/counter_staff/counter_homepage.jsp?error=missing_parameters");
                return;
            }
            
            int appointmentId = Integer.parseInt(appointmentIdStr);
            int doctorId = Integer.parseInt(doctorIdStr);
            
            // Find the appointment
            Appointment appointment = appointmentFacade.find(appointmentId);
            if (appointment == null) {
                response.sendRedirect(request.getContextPath() + "/counter_staff/counter_homepage.jsp?error=appointment_not_found");
                return;
            }
            
            // Find the doctor
            Doctor doctor = doctorFacade.find(doctorId);
            if (doctor == null) {
                response.sendRedirect(request.getContextPath() + "/counter_staff/counter_homepage.jsp?error=doctor_not_found");
                return;
            }
            
            // Validate that appointment is still pending
            if (!"pending".equals(appointment.getStatus())) {
                response.sendRedirect(request.getContextPath() + "/AppointmentServlet?action=manage&error=appointment_not_pending");
                return;
            }
            
            // Comprehensive availability check (exclude current appointment)
            AvailabilityResult availability = checkComprehensiveAvailability(
                doctorId,
                appointment.getAppointmentDate(),
                appointment.getAppointmentTime(),
                appointmentId  // Exclude current appointment
            );
            if (!availability.isAvailable()) {
                request.setAttribute("error", availability.getErrorCode());
                request.setAttribute("errorMessage", availability.getReason());
                request.getRequestDispatcher("/counter_staff/manage_customer.jsp").forward(request, response);
                return;
            }
            
            // Update appointment
            appointment.setDoctor(doctor);
            appointment.setStatus("approved");
            appointment.setCounterStaff(loggedInStaff);
            if (staffMessage != null && !staffMessage.trim().isEmpty()) {
                appointment.setStaffMessage(staffMessage.trim());
            }
            
            appointmentFacade.edit(appointment);
            
            System.out.println("=== DOCTOR ASSIGNED SUCCESSFULLY ===");
            System.out.println("Appointment ID: " + appointmentId);
            System.out.println("Assigned Doctor: " + doctor.getName());
            System.out.println("Assigned by Staff: " + loggedInStaff.getName());
            System.out.println("====================================");
            
            response.sendRedirect(request.getContextPath() + "/AppointmentServlet?action=manage&success=doctor_assigned");
            
        } catch (NumberFormatException e) {
            response.sendRedirect(request.getContextPath() + "/AppointmentServlet?action=manage&error=invalid_parameters");
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + "/AppointmentServlet?action=manage&error=assignment_failed");
        }
    }

    /**
     * Handle appointment status update - Counter staff only
     */
    private void handleUpdateAppointmentStatus(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        try {
            // Verify counter staff authorization
            HttpSession session = request.getSession();
            CounterStaff loggedInStaff = (CounterStaff) session.getAttribute("staff");
            
            if (loggedInStaff == null) {
                response.sendRedirect(request.getContextPath() + "/login.jsp");
                return;
            }
            
            String appointmentIdStr = request.getParameter("appointmentId");
            String newStatus = request.getParameter("new_status");
            String staffMessage = request.getParameter("staff_message");
            
            if (appointmentIdStr == null || appointmentIdStr.trim().isEmpty() ||
                newStatus == null || newStatus.trim().isEmpty()) {
                response.sendRedirect(request.getContextPath() + "/counter_staff/counter_homepage.jsp?error=missing_parameters");
                return;
            }
            
            int appointmentId = Integer.parseInt(appointmentIdStr);
            String trimmedStatus = newStatus.trim().toLowerCase();
            
            // Validate status
            if (!isValidStatus(trimmedStatus)) {
                response.sendRedirect(request.getContextPath() + "/counter_staff/counter_homepage.jsp?error=invalid_status");
                return;
            }
            
            // Find the appointment
            Appointment appointment = appointmentFacade.find(appointmentId);
            if (appointment == null) {
                response.sendRedirect(request.getContextPath() + "/counter_staff/counter_homepage.jsp?error=appointment_not_found");
                return;
            }
            
            String oldStatus = appointment.getStatus();
            
            // Validate status transition
            if (!isValidStatusTransition(oldStatus, trimmedStatus)) {
                response.sendRedirect(request.getContextPath() + "/counter_staff/counter_homepage.jsp?error=invalid_transition");
                return;
            }
            
            // Update appointment
            appointment.setStatus(trimmedStatus);
            appointment.setCounterStaff(loggedInStaff);
            if (staffMessage != null && !staffMessage.trim().isEmpty()) {
                appointment.setStaffMessage(staffMessage.trim());
            }
            
            appointmentFacade.edit(appointment);
            
            System.out.println("=== APPOINTMENT STATUS UPDATED ===");
            System.out.println("Appointment ID: " + appointmentId);
            System.out.println("Status changed from '" + oldStatus + "' to '" + trimmedStatus + "'");
            System.out.println("Updated by Staff: " + loggedInStaff.getName());
            System.out.println("===================================");
            
            response.sendRedirect(request.getContextPath() + "/counter_staff/counter_homepage.jsp?success=status_updated");
            
        } catch (NumberFormatException e) {
            response.sendRedirect(request.getContextPath() + "/counter_staff/counter_homepage.jsp?error=invalid_parameters");
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + "/counter_staff/counter_homepage.jsp?error=update_failed");
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
     * Helper method to find a customer by ID
     */
    private Customer findCustomerById(int customerId) {
        try {
            return customerFacade.find(customerId);
        } catch (Exception e) {
            System.out.println("Error finding customer with ID " + customerId + ": " + e.getMessage());
            return null;
        }
    }

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
     * Comprehensive availability check for appointment booking/rescheduling
 Implements cross-table validation across Schedule, LeaveRequest, and Appointment tables

 Step 1: Check if doctor is unavailable that day (LeaveRequest)
 Step 2: Get the doctor's working hours on that weekday (Schedule)
 Step 3: Check existing bookings (Appointment)
     *
     * @param doctorId The doctor's ID
     * @param appointmentDate The requested appointment date
     * @param appointmentTime The requested appointment time
     * @param excludeAppointmentId Appointment ID to exclude (for rescheduling), null for new bookings
     * @return AvailabilityResult containing availability status and detailed reason
     */
    public AvailabilityResult checkComprehensiveAvailability(int doctorId, Date appointmentDate, Time appointmentTime, Integer excludeAppointmentId) {
        try {
            System.out.println("=== COMPREHENSIVE AVAILABILITY CHECK ===");
            System.out.println("Doctor ID: " + doctorId);
            System.out.println("Date: " + appointmentDate);
            System.out.println("Time: " + appointmentTime);
            System.out.println("Exclude Appointment ID: " + excludeAppointmentId);
            
            // Step 1: Check LeaveRequest - doctor is off on specific dates
            System.out.println("\n--- Step 1: Checking Doctor Unavailability ---");
            boolean isDoctorUnavailable = scheduleUnavailableFacade.isDoctorUnavailable(doctorId, appointmentDate, appointmentTime);
            if (isDoctorUnavailable) {
                System.out.println("Doctor is unavailable at this time (marked as unavailable)");
                return new AvailabilityResult(false, "Doctor is unavailable at this time", "DOCTOR_UNAVAILABLE");
            }
            System.out.println("Doctor is not marked as unavailable");
            
            // Step 2: Check Schedule - doctor's working hours on that weekday
            System.out.println("\n--- Step 2: Checking Doctor's Schedule ---");
            Calendar cal = Calendar.getInstance();
            cal.setTime(appointmentDate);
            String dayOfWeek = getDayOfWeekString(cal.get(Calendar.DAY_OF_WEEK));
            System.out.println("Day of week: " + dayOfWeek);
            
            List<Schedule> doctorSchedules = scheduleFacade.findByDoctorAndDay(doctorId, dayOfWeek);
            if (doctorSchedules == null || doctorSchedules.isEmpty()) {
                System.out.println("Doctor does not work on " + dayOfWeek);
                return new AvailabilityResult(false, "Doctor does not work on " + dayOfWeek, "NOT_WORKING_DAY");
            }
            
            // Check if requested time falls within working hours
            boolean withinWorkingHours = false;
            for (Schedule schedule : doctorSchedules) {
                if (isTimeWithinSchedule(appointmentTime, schedule.getStartTime(), schedule.getEndTime())) {
                    withinWorkingHours = true;
                    System.out.println("Time " + appointmentTime + " is within working hours: " + 
                        schedule.getStartTime() + " - " + schedule.getEndTime());
                    break;
                }
            }
            
            if (!withinWorkingHours) {
                System.out.println("Requested time is outside doctor's working hours");
                return new AvailabilityResult(false, "Requested time is outside doctor's working hours", "OUTSIDE_WORKING_HOURS");
            }
            
            // Step 3: Check Appointment - already booked slots by other customers
            System.out.println("\n--- Step 3: Checking Existing Appointments ---");
            List<Appointment> existingAppointments = appointmentFacade.findByDoctorAndDate(doctorId, 
                new SimpleDateFormat("yyyy-MM-dd").format(appointmentDate));
            
            if (existingAppointments != null && !existingAppointments.isEmpty()) {
                for (Appointment existingApt : existingAppointments) {
                    // Skip null appointments or cancelled appointments
                    if (existingApt == null || "cancelled".equals(existingApt.getStatus()) || 
                        existingApt.getAppointmentTime() == null) {
                        continue;
                    }
                    
                    // Skip the appointment being rescheduled
                    if (excludeAppointmentId != null && existingApt.getId() == excludeAppointmentId.intValue()) {
                        System.out.println("Skipping appointment ID " + excludeAppointmentId + " (being rescheduled)");
                        continue;
                    }
                    
                    // Check for time conflict
                    if (isSameTime(existingApt.getAppointmentTime(), appointmentTime)) {
                        System.out.println("Time slot already booked by appointment ID: " + existingApt.getId());
                        System.out.println("   Existing appointment details:");
                        System.out.println("   - Patient: " + (existingApt.getCustomer() != null ? existingApt.getCustomer().getName() : "Unknown"));
                        System.out.println("   - Status: " + existingApt.getStatus());
                        System.out.println("   - Time: " + existingApt.getAppointmentTime());
                        return new AvailabilityResult(false, "Time slot already booked by another appointment", "TIME_SLOT_BOOKED");
                    }
                }
                System.out.println("No conflicting appointments found");
            } else {
                System.out.println("No existing appointments for this doctor on this date");
            }
            
            System.out.println("\n ALL CHECKS PASSED - Appointment slot is available!");
            System.out.println("=========================================");
            return new AvailabilityResult(true, "Appointment slot is available", "AVAILABLE");
            
        } catch (Exception e) {
            System.out.println("ERROR in comprehensive availability check: " + e.getMessage());
            e.printStackTrace();
            return new AvailabilityResult(false, "System error during availability check", "SYSTEM_ERROR");
        }
    }
    
    /**
     * Convert Calendar day of week to string format used in Schedule table
     */
    private String getDayOfWeekString(int calendarDayOfWeek) {
        switch (calendarDayOfWeek) {
            case Calendar.MONDAY: return "Monday";
            case Calendar.TUESDAY: return "Tuesday";
            case Calendar.WEDNESDAY: return "Wednesday";
            case Calendar.THURSDAY: return "Thursday";
            case Calendar.FRIDAY: return "Friday";
            case Calendar.SATURDAY: return "Saturday";
            case Calendar.SUNDAY: return "Sunday";
            default: return "Unknown";
        }
    }
    
    /**
     * Check if a time falls within a schedule's time range
     */
    private boolean isTimeWithinSchedule(Time appointmentTime, Time startTime, Time endTime) {
        return appointmentTime.compareTo(startTime) >= 0 && appointmentTime.compareTo(endTime) < 0;
    }
    /**
     * Check for appointment time conflicts during reschedule (excludes the appointment being rescheduled)
     * Now uses comprehensive availability checking
     */
    private boolean hasRescheduleConflict(int appointmentId, int doctorId, Date appointmentDate, Time appointmentTime) {
        AvailabilityResult result = checkComprehensiveAvailability(doctorId, appointmentDate, appointmentTime, appointmentId);
        System.out.println("Reschedule conflict check result: " + result.isAvailable() + " - " + result.getReason());
        return !result.isAvailable();
    }

    /**
     * Check for appointment time conflicts for new bookings
     * Now uses comprehensive availability checking
     */
    private boolean hasAppointmentConflict(int doctorId, Date appointmentDate, Time appointmentTime) {
        AvailabilityResult result = checkComprehensiveAvailability(doctorId, appointmentDate, appointmentTime, null);
        System.out.println("New appointment conflict check result: " + result.isAvailable() + " - " + result.getReason());
        return !result.isAvailable();
    }
    
    /**
     * Inner class to hold availability check results with detailed information
     */
    public static class AvailabilityResult {
        private final boolean available;
        private final String reason;
        private final String errorCode;
        
        public AvailabilityResult(boolean available, String reason, String errorCode) {
            this.available = available;
            this.reason = reason;
            this.errorCode = errorCode;
        }
        
        public boolean isAvailable() {
            return available;
        }
        
        public String getReason() {
            return reason;
        }
        
        public String getErrorCode() {
            return errorCode;
        }
        
        @Override
        public String toString() {
            return "AvailabilityResult{available=" + available + ", reason='" + reason + "', errorCode='" + errorCode + "'}";
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
     * Simple and efficient overdue checking - just check database status
     * No complex date calculations or mass updates needed
     */
    private void performSimpleOverdueCheck() {
        try {
            System.out.println("=== SIMPLE OVERDUE CHECK ===");
            System.out.println("Note: This method only reads appointment statuses from database");
            System.out.println("No date calculations or database updates performed");
            System.out.println("Overdue appointments are identified by status='overdue' in database");
            System.out.println("===========================");
            
            // This is intentionally simple - just log that we're checking
            // The actual overdue detection is handled by the database status field
            // which should be updated by a separate background process or admin action
            
        } catch (Exception e) {
            System.out.println("Error in simple overdue check: " + e.getMessage());
            // Don't throw - this is non-critical
        }
    }

    /**
     * Check and update appointments that are overdue - DISABLED FOR PERFORMANCE
     * An appointment is overdue if its date and time have passed but status is still "approved" or "reschedule"
     * THIS METHOD HAS BEEN DISABLED because it causes infinite loading due to:
     * 1. Loading ALL appointments from database (not just current user)
     * 2. Performing individual database UPDATE operations in a loop
     * 3. Complex date/time calculations for every appointment
     * 4. Being called on every page load
     * 
     * RECOMMENDATION: Move this to a scheduled background task or admin function
     */
    private void checkAndUpdateOverdueAppointments() {
        System.out.println("checkAndUpdateOverdueAppointments() - DISABLED FOR PERFORMANCE");
        System.out.println("This method was causing infinite loading issues.");
        System.out.println("For production use, implement this as a scheduled background task.");
        return; // Method disabled
    }

    /**
     * Automatically update appointments that are overdue
     * This method efficiently checks and updates appointment statuses in the database
     * An appointment is overdue if its date and time have passed but status is still 
     * "pending", "approved", or "reschedule"
     */
    private void updateOverdueAppointments() {
        try {
            System.out.println("=== AUTOMATIC OVERDUE UPDATE STARTED ===");
            
            // Get current date and time for comparison
            Date currentDateTime = new Date();
            System.out.println("Current system time: " + currentDateTime);
            
            // Get all appointments that could potentially be overdue
            // (Status: pending, approved, reschedule - exclude completed, cancelled, overdue)
            List<Appointment> allAppointments = appointmentFacade.findAll();
            
            if (allAppointments == null || allAppointments.isEmpty()) {
                System.out.println("No appointments found in database");
                return;
            }
            
            int totalAppointments = allAppointments.size();
            int checkedAppointments = 0;
            int updatedAppointments = 0;
            
            System.out.println("Total appointments in database: " + totalAppointments);
            
            for (Appointment appointment : allAppointments) {
                try {
                    // Skip null appointments
                    if (appointment == null) {
                        continue;
                    }
                    
                    checkedAppointments++;
                    
                    // Only check appointments that can become overdue
                    String currentStatus = appointment.getStatus();
                    if (currentStatus == null || 
                        !(currentStatus.equals("pending") || 
                          currentStatus.equals("approved") || 
                          currentStatus.equals("reschedule"))) {
                        continue;
                    }
                    
                    // Check if appointment date and time are set
                    if (appointment.getAppointmentDate() == null || 
                        appointment.getAppointmentTime() == null) {
                        System.out.println("Appointment ID " + appointment.getId() + 
                                         " has missing date/time, skipping");
                        continue;
                    }
                    
                    // Combine appointment date and time for accurate comparison
                    Calendar appointmentCalendar = Calendar.getInstance();
                    appointmentCalendar.setTime(appointment.getAppointmentDate());
                    
                    Calendar timeCalendar = Calendar.getInstance();
                    timeCalendar.setTime(appointment.getAppointmentTime());
                    
                    // Set the time components on the appointment date
                    appointmentCalendar.set(Calendar.HOUR_OF_DAY, 
                                          timeCalendar.get(Calendar.HOUR_OF_DAY));
                    appointmentCalendar.set(Calendar.MINUTE, 
                                          timeCalendar.get(Calendar.MINUTE));
                    appointmentCalendar.set(Calendar.SECOND, 0);
                    appointmentCalendar.set(Calendar.MILLISECOND, 0);
                    
                    Date appointmentDateTime = appointmentCalendar.getTime();
                    
                    // Check if appointment datetime has passed
                    if (appointmentDateTime.before(currentDateTime)) {
                        System.out.println("OVERDUE DETECTED - Appointment ID: " + appointment.getId() + 
                                         ", Status: '" + currentStatus + "'" +
                                         ", Scheduled: " + appointmentDateTime + 
                                         ", Current: " + currentDateTime);
                        
                        // Update status to overdue
                        appointment.setStatus("overdue");
                        appointmentFacade.edit(appointment);
                        updatedAppointments++;
                        
                        System.out.println("✓ Updated appointment ID " + appointment.getId() + 
                                         " from '" + currentStatus + "' to 'overdue'");
                    }
                    
                } catch (Exception appointmentException) {
                    System.out.println("Error processing appointment ID " + 
                                     (appointment != null ? appointment.getId() : "unknown") + 
                                     ": " + appointmentException.getMessage());
                    // Continue with next appointment
                }
            }
            
            System.out.println("=== OVERDUE UPDATE SUMMARY ===");
            System.out.println("Total appointments checked: " + checkedAppointments);
            System.out.println("Appointments updated to overdue: " + updatedAppointments);
            System.out.println("Overdue update completed successfully");
            System.out.println("==============================");
            
        } catch (Exception e) {
            System.out.println("ERROR in automatic overdue update: " + e.getMessage());
            e.printStackTrace();
            // Don't rethrow - this should not break the main flow
        }
    }

    /**
     * Manual trigger for overdue update (can be called from admin interface)
     * This method provides the same functionality as updateOverdueAppointments()
     * but with additional manual triggering capabilities for testing/admin use
     */
    public void manualOverdueUpdate() {
        System.out.println("=== MANUAL OVERDUE UPDATE TRIGGERED ===");
        updateOverdueAppointments();
        System.out.println("=== MANUAL OVERDUE UPDATE COMPLETED ===");
    }

    /**
     * Get current overdue appointments count (for reporting/dashboard)
     * This method returns the count without performing updates
     */
    public int getOverdueAppointmentsCount() {
        try {
            List<Appointment> allAppointments = appointmentFacade.findAll();
            if (allAppointments == null) return 0;
            
            int overdueCount = 0;
            for (Appointment appointment : allAppointments) {
                if (appointment != null && "overdue".equals(appointment.getStatus())) {
                    overdueCount++;
                }
            }
            
            System.out.println("Current overdue appointments count: " + overdueCount);
            return overdueCount;
            
        } catch (Exception e) {
            System.out.println("Error getting overdue count: " + e.getMessage());
            return 0;
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
    
    /**
     * Validate if a status is a valid appointment status
     */
    private boolean isValidStatus(String status) {
        if (status == null) return false;
        String lowerStatus = status.toLowerCase().trim();
        return "pending".equals(lowerStatus) || 
               "approved".equals(lowerStatus) || 
               "confirmed".equals(lowerStatus) ||
               "completed".equals(lowerStatus) || 
               "cancelled".equals(lowerStatus) || 
               "overdue".equals(lowerStatus) || 
               "reschedule".equals(lowerStatus);
    }

    /**
     * Validate if a status transition is allowed
     */
    private boolean isValidStatusTransition(String fromStatus, String toStatus) {
        if (fromStatus == null || toStatus == null) return false;
        
        String from = fromStatus.toLowerCase().trim();
        String to = toStatus.toLowerCase().trim();
        
        // Same status is always allowed (no change)
        if (from.equals(to)) return true;
        
        switch (from) {
            case "pending":
                // From pending: can go to approved, confirmed, cancelled, reschedule
                return "approved".equals(to) || "confirmed".equals(to) || 
                       "cancelled".equals(to) || "reschedule".equals(to);
                
            case "approved":
            case "confirmed":
                // From approved/confirmed: can go to completed, cancelled, reschedule, overdue
                return "completed".equals(to) || "cancelled".equals(to) || 
                       "reschedule".equals(to) || "overdue".equals(to);
                
            case "overdue":
                // From overdue: can go to completed, cancelled, reschedule, approved
                return "completed".equals(to) || "cancelled".equals(to) || 
                       "reschedule".equals(to) || "approved".equals(to);
                
            case "reschedule":
                // From reschedule: can go to pending, approved, cancelled
                return "pending".equals(to) || "approved".equals(to) || "cancelled".equals(to);
                
            case "completed":
                // From completed: generally final, but allow cancellation for administrative purposes
                return "cancelled".equals(to);
                
            case "cancelled":
                // From cancelled: can be reactivated to pending for administrative purposes
                return "pending".equals(to);
                
            default:
                return false;
        }
    }
    
    @Override
    public String getServletInfo() {
        return "AppointmentServlet handles all appointment operations: booking, canceling, rescheduling, and data loading";
    }
    
    /**
     * Handle manage appointments page - load and filter appointments for counter staff
     */
    private void handleManageAppointments(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        try {
            // Get filter parameters
            String searchQuery = request.getParameter("search");
            String statusFilter = request.getParameter("status");
            String doctorFilter = request.getParameter("doctor");
            String treatmentFilter = request.getParameter("treatment");
            String staffFilter = request.getParameter("staff");
            String dateFilter = request.getParameter("date");
            
            // Get all appointments
            List<Appointment> allAppointments = appointmentFacade.findAll();
            List<Appointment> filteredAppointments = new ArrayList<>();
            
            // Apply filters
            for (Appointment apt : allAppointments) {
                boolean matches = true;
                
                // Search filter (customer name, email, or appointment ID)
                if (searchQuery != null && !searchQuery.trim().isEmpty()) {
                    String search = searchQuery.toLowerCase().trim();
                    boolean searchMatches = false;
                    
                    // Check appointment ID
                    if (String.valueOf(apt.getId()).contains(search)) {
                        searchMatches = true;
                    }
                    // Check customer name and email
                    else if (apt.getCustomer() != null) {
                        String custName = apt.getCustomer().getName().toLowerCase();
                        String custEmail = apt.getCustomer().getEmail().toLowerCase();
                        if (custName.contains(search) || custEmail.contains(search)) {
                            searchMatches = true;
                        }
                    }
                    
                    if (!searchMatches) matches = false;
                }
                
                // Status filter
                if (statusFilter != null && !statusFilter.equals("all") && !statusFilter.trim().isEmpty()) {
                    String aptStatus = apt.getStatus() != null ? apt.getStatus().toLowerCase() : "pending";
                    if (!aptStatus.equals(statusFilter.toLowerCase())) {
                        matches = false;
                    }
                }
                
                // Doctor filter
                if (doctorFilter != null && !doctorFilter.equals("all") && !doctorFilter.trim().isEmpty()) {
                    try {
                        int doctorId = Integer.parseInt(doctorFilter);
                        if (apt.getDoctor() == null || apt.getDoctor().getId() != doctorId) {
                            matches = false;
                        }
                    } catch (NumberFormatException e) {
                        matches = false;
                    }
                }
                
                // Treatment filter
                if (treatmentFilter != null && !treatmentFilter.equals("all") && !treatmentFilter.trim().isEmpty()) {
                    try {
                        int treatmentId = Integer.parseInt(treatmentFilter);
                        if (apt.getTreatment() == null || apt.getTreatment().getId() != treatmentId) {
                            matches = false;
                        }
                    } catch (NumberFormatException e) {
                        matches = false;
                    }
                }
                
                // Staff filter
                if (staffFilter != null && !staffFilter.equals("all") && !staffFilter.trim().isEmpty()) {
                    if ("not_assigned".equals(staffFilter)) {
                        // Filter for appointments with no assigned counter staff (staffId is null)
                        if (apt.getCounterStaff() != null) {
                            matches = false;
                        }
                    } else {
                        try {
                            int staffId = Integer.parseInt(staffFilter);
                            if (apt.getCounterStaff() == null || apt.getCounterStaff().getId() != staffId) {
                                matches = false;
                            }
                        } catch (NumberFormatException e) {
                            matches = false;
                        }
                    }
                }
                
                // Date filter
                if (dateFilter != null && !dateFilter.trim().isEmpty()) {
                    try {
                        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
                        Date filterDate = sdf.parse(dateFilter);
                        if (apt.getAppointmentDate() == null || 
                            !sdf.format(apt.getAppointmentDate()).equals(dateFilter)) {
                            matches = false;
                        }
                    } catch (Exception e) {
                        matches = false;
                    }
                }
                
                if (matches) {
                    filteredAppointments.add(apt);
                }
            }
            
            // Load supporting data for filters
            request.setAttribute("appointmentList", filteredAppointments);
            request.setAttribute("doctorList", doctorFacade.findAll());
            request.setAttribute("treatmentList", treatmentFacade.findAll());
            request.setAttribute("staffList", counterStaffFacade.findAll());
            
            // Set filter values for form retention
            request.setAttribute("searchQuery", searchQuery);
            request.setAttribute("statusFilter", statusFilter);
            request.setAttribute("doctorFilter", doctorFilter);
            request.setAttribute("treatmentFilter", treatmentFilter);
            request.setAttribute("staffFilter", staffFilter);
            request.setAttribute("dateFilter", dateFilter);
            
            if (filteredAppointments.isEmpty()) {
                if (searchQuery != null && !searchQuery.trim().isEmpty()) {
                    request.setAttribute("infoMessage", "No appointments found matching your search criteria.");
                } else {
                    request.setAttribute("infoMessage", "No appointments found.");
                }
            }
            
            request.getRequestDispatcher("/counter_staff/manage_appointments.jsp").forward(request, response);
            
        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "system_error");
            request.setAttribute("appointmentList", new ArrayList<Appointment>());
            request.setAttribute("doctorList", doctorFacade.findAll());
            request.setAttribute("treatmentList", treatmentFacade.findAll());
            request.setAttribute("staffList", counterStaffFacade.findAll());
            request.getRequestDispatcher("/counter_staff/manage_appointments.jsp").forward(request, response);
        }
    }
    
    /**
     * Handle require reschedule request - change status to "reschedule required"
     */
    private void handleRequireReschedule(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        try {
            HttpSession session = request.getSession();
            CounterStaff loggedInStaff = (CounterStaff) session.getAttribute("staff");
            
            if (loggedInStaff == null) {
                response.sendRedirect(request.getContextPath() + "/login.jsp");
                return;
            }
            
            String appointmentIdStr = request.getParameter("appointmentId");
            String staffMessage = request.getParameter("staffMessage");
            
            if (appointmentIdStr == null || appointmentIdStr.trim().isEmpty()) {
                response.sendRedirect(request.getContextPath() + "/AppointmentServlet?action=manage&error=invalid_data");
                return;
            }
            
            int appointmentId = Integer.parseInt(appointmentIdStr);
            Appointment appointment = appointmentFacade.find(appointmentId);
            
            if (appointment == null) {
                response.sendRedirect(request.getContextPath() + "/AppointmentServlet?action=manage&error=appointment_not_found");
                return;
            }
            
            // Check if appointment can be marked for reschedule
            String currentStatus = appointment.getStatus();
            if ("completed".equals(currentStatus) || "cancelled".equals(currentStatus) || "reschedule required".equals(currentStatus)) {
                response.sendRedirect(request.getContextPath() + "/AppointmentServlet?action=manage&error=invalid_status");
                return;
            }
            
            // Update appointment status and add staff message
            appointment.setStatus("reschedule");
            
            // Create new message for each reschedule
            String newMessage = staffMessage;
            appointment.setStaffMessage(newMessage);
            
            appointmentFacade.edit(appointment);
            
            response.sendRedirect(request.getContextPath() + "/AppointmentServlet?action=manage&success=reschedule_requested");
            
        } catch (NumberFormatException e) {
            response.sendRedirect(request.getContextPath() + "/AppointmentServlet?action=manage&error=invalid_data");
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + "/AppointmentServlet?action=manage&error=system_error");
        }
    }
    
    // Handle AJAX request to get appointment details for reschedule
    private void handleGetAppointmentDetails(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        
        try {
            String appointmentIdStr = request.getParameter("appointmentId");
            if (appointmentIdStr == null || appointmentIdStr.trim().isEmpty()) {
                response.getWriter().write("{\"error\": \"Invalid appointment ID\"}");
                return;
            }

            int appointmentId = Integer.parseInt(appointmentIdStr);
            Appointment appointment = appointmentFacade.find(appointmentId);

            if (appointment == null) {
                response.getWriter().write("{\"error\": \"Appointment not found\"}");
                return;
            }

            // Check if appointment can be rescheduled
            String status = appointment.getStatus();
            if (!"pending".equals(status) && !"approved".equals(status) && 
                !"overdue".equals(status) && !"reschedule required".equals(status)) {
                response.getWriter().write("{\"error\": \"This appointment cannot be rescheduled\"}");
                return;
            }

            // Build JSON response
            StringBuilder json = new StringBuilder();
            json.append("{");
            json.append("\"appointment\": {");
            json.append("\"id\": ").append(appointment.getId()).append(",");
            json.append("\"status\": \"").append(appointment.getStatus()).append("\",");

            // Format date and time
            SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd");
            SimpleDateFormat timeFormat = new SimpleDateFormat("HH:mm");
            String dateStr = appointment.getAppointmentDate() != null ? dateFormat.format(appointment.getAppointmentDate()) : "";
            String timeStr = appointment.getAppointmentTime() != null ? timeFormat.format(appointment.getAppointmentTime()) : "";

            json.append("\"date\": \"").append(dateStr).append("\",");
            json.append("\"time\": \"").append(timeStr).append("\",");

            // Customer info
            json.append("\"customer\": {");
            json.append("\"id\": ").append(appointment.getCustomer().getId()).append(",");
            json.append("\"name\": \"").append(appointment.getCustomer().getName()).append("\",");
            json.append("\"email\": \"").append(appointment.getCustomer().getEmail()).append("\",");
            json.append("\"phoneNumber\": \"").append(appointment.getCustomer().getPhone() != null ? appointment.getCustomer().getPhone() : "").append("\"");
            json.append("},");

            // Treatment info
            json.append("\"treatment\": {");
            json.append("\"id\": ").append(appointment.getTreatment().getId()).append(",");
            json.append("\"name\": \"").append(appointment.getTreatment().getName()).append("\"");
            json.append("},");

            // Doctor info (if assigned)
            if (appointment.getDoctor() != null) {
                json.append("\"doctor\": {");
                json.append("\"id\": ").append(appointment.getDoctor().getId()).append(",");
                json.append("\"name\": \"").append(appointment.getDoctor().getName()).append("\"");
                json.append("}");
            } else {
                json.append("\"doctor\": null");
            }

            json.append("}"); // close appointment object
            json.append("}"); // close root object

            response.getWriter().write(json.toString());
            
        } catch (NumberFormatException e) {
            System.err.println("Invalid appointment ID format: " + e.getMessage()); // Debugging log
            response.getWriter().write("{\"error\": \"Invalid appointment ID format\"}");
        } catch (Exception e) {
            System.err.println("System error occurred: " + e.getMessage()); // Debugging log
            e.printStackTrace(); // Debugging log
            response.getWriter().write("{\"error\": \"System error occurred\"}");
        }
    }
    
    // Handle view appointment details
    private void handleViewAppointmentDetails(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        // Check authentication
        HttpSession session = request.getSession();
        CounterStaff loggedInStaff = (CounterStaff) session.getAttribute("staff");
        Customer loggedInCustomer = (Customer) session.getAttribute("customer");
        
        if (loggedInStaff == null && loggedInCustomer == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }
        
        String appointmentIdStr = request.getParameter("id");
        if (appointmentIdStr == null || appointmentIdStr.trim().isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/AppointmentServlet?action=manage&error=invalid_data");
            return;
        }
        
        try {
            int appointmentId = Integer.parseInt(appointmentIdStr);
            Appointment appointment = appointmentFacade.find(appointmentId);
            
            if (appointment == null) {
                response.sendRedirect(request.getContextPath() + "/AppointmentServlet?action=manage&error=appointment_not_found");
                return;
            }
            
            // Set appointment data for JSON response
            response.setContentType("application/json");
            response.setCharacterEncoding("UTF-8");
            
            // Build JSON response with appointment details
            StringBuilder json = new StringBuilder();
            json.append("{");
            json.append("\"appointment\": {");
            json.append("\"id\": ").append(appointment.getId()).append(",");
            json.append("\"status\": \"").append(appointment.getStatus() != null ? appointment.getStatus() : "").append("\",");
            
            // Customer info
            if (appointment.getCustomer() != null) {
                json.append("\"customer\": {");
                json.append("\"id\": ").append(appointment.getCustomer().getId()).append(",");
                json.append("\"name\": \"").append(appointment.getCustomer().getName() != null ? appointment.getCustomer().getName() : "").append("\",");
                json.append("\"email\": \"").append(appointment.getCustomer().getEmail() != null ? appointment.getCustomer().getEmail() : "").append("\",");
                json.append("\"phone\": \"").append(appointment.getCustomer().getPhone() != null ? appointment.getCustomer().getPhone() : "").append("\",");
                json.append("\"gender\": \"").append(appointment.getCustomer().getGender() != null ? appointment.getCustomer().getGender() : "").append("\"");
                json.append("},");
            } else {
                json.append("\"customer\": null,");
            }
            
            // Treatment info
            if (appointment.getTreatment() != null) {
                json.append("\"treatment\": {");
                json.append("\"id\": ").append(appointment.getTreatment().getId()).append(",");
                json.append("\"name\": \"").append(appointment.getTreatment().getName() != null ? appointment.getTreatment().getName() : "").append("\"");
                json.append("},");
            } else {
                json.append("\"treatment\": null,");
            }
            
            // Doctor info
            if (appointment.getDoctor() != null) {
                json.append("\"doctor\": {");
                json.append("\"id\": ").append(appointment.getDoctor().getId()).append(",");
                json.append("\"name\": \"").append(appointment.getDoctor().getName() != null ? appointment.getDoctor().getName() : "").append("\",");
                json.append("\"specialization\": \"").append(appointment.getDoctor().getSpecialization() != null ? appointment.getDoctor().getSpecialization() : "").append("\"");
                json.append("},");
            } else {
                json.append("\"doctor\": null,");
            }
            
            // Staff info
            if (appointment.getCounterStaff() != null) {
                json.append("\"staff\": {");
                json.append("\"id\": ").append(appointment.getCounterStaff().getId()).append(",");
                json.append("\"name\": \"").append(appointment.getCounterStaff().getName() != null ? appointment.getCounterStaff().getName() : "").append("\"");
                json.append("},");
            } else {
                json.append("\"staff\": null,");
            }
            
            // Date and time
            SimpleDateFormat dateFormat = new SimpleDateFormat("dd MMM yyyy");
            SimpleDateFormat timeFormat = new SimpleDateFormat("HH:mm");
            json.append("\"date\": \"").append(appointment.getAppointmentDate() != null ? dateFormat.format(appointment.getAppointmentDate()) : "").append("\",");
            json.append("\"time\": \"").append(appointment.getAppointmentTime() != null ? timeFormat.format(appointment.getAppointmentTime()) : "").append("\",");
            
            // Messages
            json.append("\"customerMessage\": \"").append(appointment.getCustMessage() != null ? appointment.getCustMessage().replace("\"", "\\\"") : "").append("\",");
            json.append("\"doctorMessage\": \"").append(appointment.getDocMessage() != null ? appointment.getDocMessage().replace("\"", "\\\"") : "").append("\",");
            json.append("\"staffMessage\": \"").append(appointment.getStaffMessage() != null ? appointment.getStaffMessage().replace("\"", "\\\"") : "").append("\"");
            
            json.append("}"); // close appointment object
            json.append("}"); // close root object
            
            response.getWriter().write(json.toString());
            
        } catch (NumberFormatException e) {
            response.sendRedirect(request.getContextPath() + "/AppointmentServlet?action=manage&error=invalid_data");
        }
    }
    
    // Handle getting available doctors for assignment
    private void handleGetAvailableDoctors(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        
        try {
            // Check authentication
            HttpSession session = request.getSession();
            CounterStaff loggedInStaff = (CounterStaff) session.getAttribute("staff");
            
            if (loggedInStaff == null) {
                response.getWriter().write("{\"error\": \"Authentication required\"}");
                return;
            }
            
            String appointmentIdStr = request.getParameter("appointmentId");
            if (appointmentIdStr == null || appointmentIdStr.trim().isEmpty()) {
                response.getWriter().write("{\"error\": \"Invalid appointment ID\"}");
                return;
            }
            
            int appointmentId = Integer.parseInt(appointmentIdStr);
            Appointment appointment = appointmentFacade.find(appointmentId);
            
            if (appointment == null) {
                response.getWriter().write("{\"error\": \"Appointment not found\"}");
                return;
            }
            
            // Get all doctors
            List<Doctor> allDoctors = doctorFacade.findAll();
            List<Doctor> availableDoctors = new ArrayList<>();
            
            // Filter doctors based on availability and specialization match
            for (Doctor doctor : allDoctors) {
                // Check if doctor is available at the appointment time
                if (!hasAppointmentConflict(doctor.getId(), appointment.getAppointmentDate(), appointment.getAppointmentTime())) {
                    availableDoctors.add(doctor);
                }
            }
            
            // Build JSON response
            StringBuilder json = new StringBuilder();
            json.append("{\"doctors\": [");
            
            for (int i = 0; i < availableDoctors.size(); i++) {
                Doctor doctor = availableDoctors.get(i);
                if (i > 0) json.append(",");
                
                json.append("{");
                json.append("\"id\": ").append(doctor.getId()).append(",");
                json.append("\"name\": \"").append(doctor.getName() != null ? doctor.getName() : "").append("\",");
                json.append("\"specialization\": \"").append(doctor.getSpecialization() != null ? doctor.getSpecialization() : "").append("\"");
                json.append("}");
            }
            
            json.append("]}");
            response.getWriter().write(json.toString());
            
        } catch (NumberFormatException e) {
            response.getWriter().write("{\"error\": \"Invalid appointment ID format\"}");
        } catch (Exception e) {
            response.getWriter().write("{\"error\": \"System error occurred\"}");
        }
    }
    
    // Handle checking doctor availability for assignment (AJAX endpoint)
    private void handleCheckDoctorAvailability(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        
        try {
            // Check authentication
            HttpSession session = request.getSession();
            CounterStaff loggedInStaff = (CounterStaff) session.getAttribute("staff");
            
            if (loggedInStaff == null) {
                response.getWriter().write("{\"error\": \"Authentication required\"}");
                return;
            }
            
            String appointmentIdStr = request.getParameter("appointmentId");
            String doctorIdStr = request.getParameter("doctorId");
            
            if (appointmentIdStr == null || appointmentIdStr.trim().isEmpty() ||
                doctorIdStr == null || doctorIdStr.trim().isEmpty()) {
                response.getWriter().write("{\"error\": \"Missing parameters\"}");
                return;
            }
            
            int appointmentId = Integer.parseInt(appointmentIdStr);
            int doctorId = Integer.parseInt(doctorIdStr);
            
            // Get appointment details
            Appointment appointment = appointmentFacade.find(appointmentId);
            if (appointment == null) {
                response.getWriter().write("{\"error\": \"Appointment not found\"}");
                return;
            }
            
            // Check doctor availability using existing comprehensive availability check
            // Exclude the current appointment from availability check
            AvailabilityResult availability = checkComprehensiveAvailability(
                doctorId,
                appointment.getAppointmentDate(),
                appointment.getAppointmentTime(),
                appointmentId  // Exclude current appointment
            );
            
            // Build JSON response
            StringBuilder json = new StringBuilder();
            json.append("{");
            json.append("\"available\": ").append(availability.isAvailable()).append(",");
            json.append("\"reason\": \"").append(availability.getReason() != null ? availability.getReason() : "").append("\",");
            json.append("\"errorCode\": \"").append(availability.getErrorCode() != null ? availability.getErrorCode() : "").append("\"");
            json.append("}");
            
            response.getWriter().write(json.toString());
            
        } catch (NumberFormatException e) {
            response.getWriter().write("{\"error\": \"Invalid parameter format\"}");
        } catch (Exception e) {
            e.printStackTrace();
            response.getWriter().write("{\"error\": \"System error occurred\"}");
        }
    }
    
    /**
     * Post-booking validation: Check affected appointments when doctor unavailability is added
 This method should be called when a new LeaveRequest entry is created
 It automatically changes affected appointment statuses and clears staffId
     * 
     * @param scheduleUnavailable The new unavailability record
     * @return Number of appointments affected
     */
    public int handlePostBookingValidation(LeaveRequest scheduleUnavailable) {
        int affectedCount = 0;
        
        try {
            System.out.println("=== POST-BOOKING VALIDATION ===");
            System.out.println("Doctor ID: " + scheduleUnavailable.getDoctor().getId());
            System.out.println("Unavailable Date: " + scheduleUnavailable.getUnavailableDate());
            System.out.println("Unavailable Time: " + scheduleUnavailable.getStartTime() + " - " + scheduleUnavailable.getEndTime());
            
            // Find appointments that conflict with this unavailability
            List<Appointment> allAppointments = appointmentFacade.findByDoctorAndDate(
                scheduleUnavailable.getDoctor().getId(),
                new SimpleDateFormat("yyyy-MM-dd").format(scheduleUnavailable.getUnavailableDate())
            );
            
            if (allAppointments == null || allAppointments.isEmpty()) {
                System.out.println("No appointments found for this doctor on this date");
                return 0;
            }
            
            System.out.println("Checking " + allAppointments.size() + " appointments for conflicts");
            
            for (Appointment appointment : allAppointments) {
                try {
                    // Skip null appointments or already processed ones
                    if (appointment == null || appointment.getAppointmentTime() == null) {
                        continue;
                    }
                    
                    // Skip appointments that are already cancelled or completed
                    String currentStatus = appointment.getStatus();
                    if ("cancelled".equals(currentStatus) || "completed".equals(currentStatus)) {
                        System.out.println("Skipping appointment ID " + appointment.getId() + " - already " + currentStatus);
                        continue;
                    }
                    
                    // Check if appointment time conflicts with unavailability
                    Time appointmentTime = appointment.getAppointmentTime();
                    Time unavailableStart = scheduleUnavailable.getStartTime();
                    Time unavailableEnd = scheduleUnavailable.getEndTime();
                    
                    // Check if appointment time falls within unavailable period
                    if (appointmentTime.compareTo(unavailableStart) >= 0 && 
                        appointmentTime.compareTo(unavailableEnd) < 0) {
                        
                        System.out.println("CONFLICT DETECTED!");
                        System.out.println("  Appointment ID: " + appointment.getId());
                        System.out.println("  Current Status: " + currentStatus);
                        System.out.println("  Appointment Time: " + appointmentTime);
                        System.out.println("  Unavailable Period: " + unavailableStart + " - " + unavailableEnd);
                        
                        // Update appointment status based on current status
                        String newStatus = "reschedule";
                        if ("approved".equals(currentStatus)) {
                            newStatus = "reschedule";
                            System.out.println("  Status change: Approved → Reschedule Required");
                        } else if ("pending".equals(currentStatus)) {
                            newStatus = "reschedule";
                            System.out.println("  Status change: Pending → Reschedule Required"); 
                        }
                        
                        // Update the appointment
                        appointment.setStatus(newStatus);
                        
                        // Clear staffId automatically (as per requirement)
                        appointment.setCounterStaff(null);
                        System.out.println("  Staff ID cleared - will display 'Not assigned'");
                        
                        // Add automatic staff message explaining the change
                        String autoMessage = "Appointment requires rescheduling due to doctor unavailability on " + 
                            scheduleUnavailable.getUnavailableDate() + " from " + 
                            unavailableStart + " to " + unavailableEnd;
                        if (scheduleUnavailable.getReason() != null && !scheduleUnavailable.getReason().trim().isEmpty()) {
                            autoMessage += ". Reason: " + scheduleUnavailable.getReason();
                        }
                        appointment.setStaffMessage(autoMessage);
                        
                        // Save the updated appointment
                        appointmentFacade.edit(appointment);
                        affectedCount++;
                        
                        System.out.println("Appointment updated successfully");
                    }
                    
                } catch (Exception appointmentException) {
                    System.out.println("Error processing appointment ID " + appointment.getId() + ": " + appointmentException.getMessage());
                    appointmentException.printStackTrace();
                }
            }
            
            System.out.println("=== POST-BOOKING VALIDATION COMPLETE ===");
            System.out.println("Total appointments affected: " + affectedCount);
            System.out.println("========================================");
            
            return affectedCount;
            
        } catch (Exception e) {
            System.out.println("ERROR in post-booking validation: " + e.getMessage());
            e.printStackTrace();
            return affectedCount;
        }
    }

}
