import java.io.IOException;
import java.sql.Time;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import javax.ejb.EJB;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import model.Doctor;
import model.Schedule;
import model.ScheduleFacade;
import model.ScheduleHelper;
import model.ScheduleHelper.ConsolidatedSchedule;

@WebServlet(name = "ScheduleServlet", urlPatterns = {"/ScheduleServlet"})
public class ScheduleServlet extends HttpServlet {

    @EJB
    private ScheduleFacade scheduleFacade;

    /**
     * Processes requests for both HTTP <code>GET</code> and <code>POST</code> methods.
     *
     * @param request servlet request
     * @param response servlet response
     * @throws ServletException if a servlet-specific error occurs
     * @throws IOException if an I/O error occurs
     */
    protected void processRequest(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("doctor") == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        Doctor doctor = (Doctor) session.getAttribute("doctor");
        String action = request.getParameter("action");

        if (action == null) {
            action = "manage"; // Default action
        }

        switch (action) {
            case "manage":
                showScheduleManagement(request, response, doctor);
                break;
            case "add":
                addSchedule(request, response, doctor);
                break;
            case "edit":
                editSchedule(request, response, doctor);
                break;
            case "update":
                updateSchedule(request, response, doctor);
                break;
            case "updateFull":
                updateFullSchedule(request, response, doctor);
                break;
            case "delete":
                deleteSchedule(request, response, doctor);
                break;
            case "deleteFull":
                deleteFullSchedule(request, response, doctor);
                break;
            default:
                showScheduleManagement(request, response, doctor);
                break;
        }
    }

    private void showScheduleManagement(HttpServletRequest request, HttpServletResponse response, Doctor doctor)
            throws ServletException, IOException {
        // Get doctor's schedule
        List<Schedule> schedules = scheduleFacade.findByDoctorId(doctor.getId());
        
        // Sort schedules by day of week and time
        Collections.sort(schedules, new ScheduleComparator());
        
        // Use ScheduleHelper to consolidate schedules for display
        List<ScheduleHelper.ConsolidatedSchedule> consolidatedSchedules = ScheduleHelper.consolidateSchedules(schedules);
        
        // Sort consolidated schedules by day of week
        Collections.sort(consolidatedSchedules, new ConsolidatedScheduleComparator());
        
        request.setAttribute("schedules", schedules); // Keep original for compatibility
        request.setAttribute("consolidatedSchedules", consolidatedSchedules);
        request.getRequestDispatcher("/doctor/manage_schedule.jsp").forward(request, response);
    }
    
    /**
     * Comparator for sorting schedules by day of week and time
     */
    private static class ScheduleComparator implements Comparator<Schedule> {
        // Map to define the order of days
        private static final Map<String, Integer> DAY_ORDER = new HashMap<>();
        static {
            DAY_ORDER.put("Monday", 1);
            DAY_ORDER.put("Tuesday", 2);
            DAY_ORDER.put("Wednesday", 3);
            DAY_ORDER.put("Thursday", 4);
            DAY_ORDER.put("Friday", 5);
        }
        
        @Override
        public int compare(Schedule s1, Schedule s2) {
            // First compare by day of week
            int dayComparison = Integer.compare(
                    DAY_ORDER.getOrDefault(s1.getDayOfWeek(), 999),
                    DAY_ORDER.getOrDefault(s2.getDayOfWeek(), 999)
            );
            
            if (dayComparison != 0) {
                return dayComparison;
            }
            
            // If same day, compare by start time
            return s1.getStartTime().compareTo(s2.getStartTime());
        }
    }
    
    /**
     * Comparator for sorting consolidated schedules by day of week and time
     */
    private static class ConsolidatedScheduleComparator implements Comparator<ScheduleHelper.ConsolidatedSchedule> {
        // Map to define the order of days
        private static final Map<String, Integer> DAY_ORDER = new HashMap<>();
        static {
            DAY_ORDER.put("Monday", 1);
            DAY_ORDER.put("Tuesday", 2);
            DAY_ORDER.put("Wednesday", 3);
            DAY_ORDER.put("Thursday", 4);
            DAY_ORDER.put("Friday", 5);
        }
        
        @Override
        public int compare(ScheduleHelper.ConsolidatedSchedule s1, ScheduleHelper.ConsolidatedSchedule s2) {
            // Compare by day of week
            int dayComparison = Integer.compare(
                    DAY_ORDER.getOrDefault(s1.getDayOfWeek(), 999),
                    DAY_ORDER.getOrDefault(s2.getDayOfWeek(), 999)
            );
            
            if (dayComparison != 0) {
                return dayComparison;
            }
            
            // If same day, compare by start time
            return s1.getDisplayStartTime().compareTo(s2.getDisplayStartTime());
        }
    }

    private void addSchedule(HttpServletRequest request, HttpServletResponse response, Doctor doctor)
            throws ServletException, IOException {
        try {
            // Get form parameters
            String dayOfWeek = request.getParameter("dayOfWeek");
            String startTimeStr = request.getParameter("startTime");
            String endTimeStr = request.getParameter("endTime");
            
            // Validate inputs
            String error = validateScheduleInput(dayOfWeek, startTimeStr, endTimeStr);
            if (error != null) {
                request.setAttribute("error", error);
                showScheduleManagement(request, response, doctor);
                return;
            }
            
            // Convert string times to Time objects
            Time startTime = Time.valueOf(startTimeStr + ":00");
            Time endTime = Time.valueOf(endTimeStr + ":00");
            
            // Check for schedule conflicts with existing schedules
            boolean hasConflict = checkScheduleConflict(doctor.getId(), dayOfWeek, startTime, endTime, 0);
            if (hasConflict) {
                request.setAttribute("error", "This schedule conflicts with an existing schedule. Please select a different time.");
                showScheduleManagement(request, response, doctor);
                return;
            }
            
            // Create and save the new schedule
            Schedule schedule = new Schedule();
            schedule.setDoctor(doctor);
            schedule.setDayOfWeek(dayOfWeek);
            schedule.setStartTime(startTime);
            schedule.setEndTime(endTime);
            
            // Check if schedule spans lunch break (12:00 - 13:00)
            try {
                SimpleDateFormat timeFormat = new SimpleDateFormat("HH:mm");
                java.util.Date scheduleStart = timeFormat.parse(startTimeStr);
                java.util.Date scheduleEnd = timeFormat.parse(endTimeStr);
                java.util.Date lunchStart = timeFormat.parse("12:00");
                java.util.Date lunchEnd = timeFormat.parse("13:00");
                
                boolean spansLunch = scheduleStart.before(lunchStart) && scheduleEnd.after(lunchEnd);
                
                if (spansLunch) {
                    // Create morning schedule (original start time to 12:00)
                    Schedule morningSchedule = new Schedule();
                    morningSchedule.setDoctor(doctor);
                    morningSchedule.setDayOfWeek(dayOfWeek);
                    morningSchedule.setStartTime(startTime);
                    morningSchedule.setEndTime(Time.valueOf("12:00:00"));
                    
                    // Create afternoon schedule (13:00 to original end time)
                    Schedule afternoonSchedule = new Schedule();
                    afternoonSchedule.setDoctor(doctor);
                    afternoonSchedule.setDayOfWeek(dayOfWeek);
                    afternoonSchedule.setStartTime(Time.valueOf("13:00:00"));
                    afternoonSchedule.setEndTime(endTime);
                    
                    // Save both schedules
                    scheduleFacade.create(morningSchedule);
                    scheduleFacade.create(afternoonSchedule);
                    
                    request.setAttribute("success", "Schedule that spans lunch break has been added as two separate schedules.");
                } else {
                    // Save the original schedule
                    scheduleFacade.create(schedule);
                    request.setAttribute("success", "Schedule added successfully.");
                }
            } catch (Exception e) {
                // If any error occurs, save the original schedule
                scheduleFacade.create(schedule);
                request.setAttribute("success", "Schedule added successfully.");
            }
            showScheduleManagement(request, response, doctor); // This will automatically sort the schedules
            
        } catch (Exception e) {
            request.setAttribute("error", "Failed to add schedule: " + e.getMessage());
            showScheduleManagement(request, response, doctor);
        }
    }

    private void editSchedule(HttpServletRequest request, HttpServletResponse response, Doctor doctor)
            throws ServletException, IOException {
        try {
            // Debug info
            System.out.println("Edit schedule params: " + request.getParameterMap().keySet());
            System.out.println("spansLunch param: " + request.getParameter("spansLunch"));
            
            int scheduleId = Integer.parseInt(request.getParameter("id"));
            Schedule schedule = scheduleFacade.find(scheduleId);
            
            if (schedule == null || schedule.getDoctor().getId() != doctor.getId()) {
                request.setAttribute("error", "Schedule not found or you don't have permission to edit it.");
                showScheduleManagement(request, response, doctor);
                return;
            }
            
            // Check if this is a schedule that spans lunch
            String spansLunchParam = request.getParameter("spansLunch");
            boolean spansLunch = spansLunchParam != null && spansLunchParam.equals("true");
            
            System.out.println("spansLunch: " + spansLunch);
            
            if (spansLunch) {
                // This is the morning part of a schedule that spans lunch
                // Find the afternoon part (starts at 1pm on the same day)
                List<Schedule> schedules = scheduleFacade.findByDoctorId(doctor.getId());
                Schedule afternoonSchedule = null;
                
                System.out.println("Morning schedule: Day=" + schedule.getDayOfWeek() + 
                                 ", Start=" + schedule.getStartTime() + 
                                 ", End=" + schedule.getEndTime());
                
                for (Schedule s : schedules) {
                    System.out.println("Checking schedule: ID=" + s.getId() + 
                                     ", Day=" + s.getDayOfWeek() + 
                                     ", Start=" + s.getStartTime() + 
                                     ", End=" + s.getEndTime());
                                     
                    if (s.getDayOfWeek().equals(schedule.getDayOfWeek()) && 
                        s.getStartTime().toString().startsWith("13:00") &&
                        s.getId() != schedule.getId()) {
                        afternoonSchedule = s;
                        System.out.println("Found afternoon schedule: ID=" + s.getId());
                        break;
                    }
                }
                
                if (afternoonSchedule != null) {
                    request.setAttribute("afternoonSchedule", afternoonSchedule);
                    System.out.println("Set afternoonSchedule attribute");
                } else {
                    System.out.println("No afternoon schedule found!");
                }
            }
            
            request.setAttribute("schedule", schedule);
            request.getRequestDispatcher("/doctor/edit_schedule.jsp").forward(request, response);
            
        } catch (NumberFormatException e) {
            e.printStackTrace();
            request.setAttribute("error", "Invalid schedule ID: " + e.getMessage());
            showScheduleManagement(request, response, doctor);
        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Error editing schedule: " + e.getMessage());
            showScheduleManagement(request, response, doctor);
        }
    }

    private void updateSchedule(HttpServletRequest request, HttpServletResponse response, Doctor doctor)
            throws ServletException, IOException {
        try {
            int scheduleId = Integer.parseInt(request.getParameter("id"));
            Schedule schedule = scheduleFacade.find(scheduleId);
            
            if (schedule == null || schedule.getDoctor().getId() != doctor.getId()) {
                request.setAttribute("error", "Schedule not found or you don't have permission to edit it.");
                showScheduleManagement(request, response, doctor);
                return;
            }
            
            String dayOfWeek = request.getParameter("dayOfWeek");
            String startTimeStr = request.getParameter("startTime");
            String endTimeStr = request.getParameter("endTime");
            
            // Validate inputs
            String error = validateScheduleInput(dayOfWeek, startTimeStr, endTimeStr);
            if (error != null) {
                request.setAttribute("error", error);
                request.setAttribute("schedule", schedule);
                request.getRequestDispatcher("/doctor/edit_schedule.jsp").forward(request, response);
                return;
            }
            
            // Convert string times to Time objects
            Time startTime = Time.valueOf(startTimeStr + ":00");
            Time endTime = Time.valueOf(endTimeStr + ":00");
            
            // Check for schedule conflicts with existing schedules (excluding this schedule)
            boolean hasConflict = checkScheduleConflict(doctor.getId(), dayOfWeek, startTime, endTime, scheduleId);
            if (hasConflict) {
                request.setAttribute("error", "This schedule conflicts with an existing schedule. Please select a different time.");
                request.setAttribute("schedule", schedule);
                request.getRequestDispatcher("/doctor/edit_schedule.jsp").forward(request, response);
                return;
            }
            
            // Update the schedule
            schedule.setDayOfWeek(dayOfWeek);
            schedule.setStartTime(startTime);
            schedule.setEndTime(endTime);
            
            // Check if schedule spans lunch break (12:00 - 13:00)
            try {
                SimpleDateFormat timeFormat = new SimpleDateFormat("HH:mm");
                java.util.Date scheduleStart = timeFormat.parse(startTimeStr);
                java.util.Date scheduleEnd = timeFormat.parse(endTimeStr);
                java.util.Date lunchStart = timeFormat.parse("12:00");
                java.util.Date lunchEnd = timeFormat.parse("13:00");
                
                boolean spansLunch = scheduleStart.before(lunchStart) && scheduleEnd.after(lunchEnd);
                
                if (spansLunch) {
                    // Check if there's already a paired schedule (across lunch)
                    List<Schedule> daySchedules = scheduleFacade.findByDoctorAndDay(doctor.getId(), dayOfWeek);
                    Schedule pairedSchedule = null;
                    
                    for (Schedule s : daySchedules) {
                        if (s.getId() != scheduleId) {
                            // Look for a schedule that might be the afternoon part
                            if (s.getStartTime().toString().startsWith("13:00") && 
                                s.getEndTime().equals(endTime)) {
                                pairedSchedule = s;
                                break;
                            }
                            // Or the morning part
                            if (s.getEndTime().toString().startsWith("12:00") && 
                                s.getStartTime().equals(startTime)) {
                                pairedSchedule = s;
                                break;
                            }
                        }
                    }
                    
                    if (pairedSchedule != null) {
                        // Update existing paired schedules
                        if (pairedSchedule.getStartTime().toString().startsWith("13:00")) {
                            // Current is morning, paired is afternoon
                            schedule.setEndTime(Time.valueOf("12:00:00"));
                            scheduleFacade.edit(schedule);
                            
                            pairedSchedule.setEndTime(endTime);
                            scheduleFacade.edit(pairedSchedule);
                        } else {
                            // Current is afternoon, paired is morning
                            schedule.setStartTime(Time.valueOf("13:00:00"));
                            scheduleFacade.edit(schedule);
                            
                            pairedSchedule.setStartTime(startTime);
                            scheduleFacade.edit(pairedSchedule);
                        }
                    } else {
                        // Create a new schedule for the other half
                        if (schedule.getStartTime().before(Time.valueOf("12:00:00"))) {
                            // Current is morning, create afternoon
                            schedule.setEndTime(Time.valueOf("12:00:00"));
                            scheduleFacade.edit(schedule);
                            
                            Schedule afternoonSchedule = new Schedule();
                            afternoonSchedule.setDoctor(doctor);
                            afternoonSchedule.setDayOfWeek(dayOfWeek);
                            afternoonSchedule.setStartTime(Time.valueOf("13:00:00"));
                            afternoonSchedule.setEndTime(endTime);
                            scheduleFacade.create(afternoonSchedule);
                        } else {
                            // Current is afternoon, create morning
                            schedule.setStartTime(Time.valueOf("13:00:00"));
                            scheduleFacade.edit(schedule);
                            
                            Schedule morningSchedule = new Schedule();
                            morningSchedule.setDoctor(doctor);
                            morningSchedule.setDayOfWeek(dayOfWeek);
                            morningSchedule.setStartTime(startTime);
                            morningSchedule.setEndTime(Time.valueOf("12:00:00"));
                            scheduleFacade.create(morningSchedule);
                        }
                    }
                    request.setAttribute("success", "Schedule that spans lunch break has been updated as two separate schedules.");
                } else {
                    // Just update the single schedule
                    scheduleFacade.edit(schedule);
                    request.setAttribute("success", "Schedule updated successfully.");
                }
            } catch (Exception e) {
                // If any error occurs, just update the original schedule
                scheduleFacade.edit(schedule);
                request.setAttribute("success", "Schedule updated successfully.");
            }
            showScheduleManagement(request, response, doctor); // This will automatically sort the schedules
            
        } catch (NumberFormatException e) {
            request.setAttribute("error", "Invalid schedule ID.");
            showScheduleManagement(request, response, doctor);
        } catch (Exception e) {
            request.setAttribute("error", "Failed to update schedule: " + e.getMessage());
            showScheduleManagement(request, response, doctor);
        }
    }

    private void deleteSchedule(HttpServletRequest request, HttpServletResponse response, Doctor doctor)
            throws ServletException, IOException {
        try {
            int scheduleId = Integer.parseInt(request.getParameter("id"));
            Schedule schedule = scheduleFacade.find(scheduleId);
            
            if (schedule == null || schedule.getDoctor().getId() != doctor.getId()) {
                request.setAttribute("error", "Schedule not found or you don't have permission to delete it.");
                showScheduleManagement(request, response, doctor);
                return;
            }
            
            scheduleFacade.remove(schedule);
            
            request.setAttribute("success", "Schedule deleted successfully.");
            showScheduleManagement(request, response, doctor); // This will automatically sort the schedules
            
        } catch (NumberFormatException e) {
            request.setAttribute("error", "Invalid schedule ID.");
            showScheduleManagement(request, response, doctor);
        } catch (Exception e) {
            request.setAttribute("error", "Failed to delete schedule: " + e.getMessage());
            showScheduleManagement(request, response, doctor);
        }
    }
    
    /**
     * Deletes a full schedule (both morning and afternoon parts when spanning lunch)
     */
    private void deleteFullSchedule(HttpServletRequest request, HttpServletResponse response, Doctor doctor)
            throws ServletException, IOException {
        try {
            // Debug logging
            System.out.println("Deleting full schedule...");
            System.out.println("Parameters: " + request.getParameterMap().keySet());
            System.out.println("morningId param: " + request.getParameter("morningId"));
            System.out.println("afternoonId param: " + request.getParameter("afternoonId"));
            
            int morningId = Integer.parseInt(request.getParameter("morningId"));
            int afternoonId = Integer.parseInt(request.getParameter("afternoonId"));
            
            Schedule morningSchedule = scheduleFacade.find(morningId);
            Schedule afternoonSchedule = scheduleFacade.find(afternoonId);
            
            if (morningSchedule == null || afternoonSchedule == null || 
                morningSchedule.getDoctor().getId() != doctor.getId() || 
                afternoonSchedule.getDoctor().getId() != doctor.getId()) {
                request.setAttribute("error", "Schedule not found or you don't have permission to delete it.");
                showScheduleManagement(request, response, doctor);
                return;
            }
            
            // Delete both schedules
            scheduleFacade.remove(morningSchedule);
            scheduleFacade.remove(afternoonSchedule);
            
            request.setAttribute("success", "Full schedule deleted successfully.");
            showScheduleManagement(request, response, doctor);
            
        } catch (NumberFormatException e) {
            request.setAttribute("error", "Invalid schedule ID: " + e.getMessage());
            showScheduleManagement(request, response, doctor);
        } catch (Exception e) {
            e.printStackTrace(); // Print stack trace for debugging
            request.setAttribute("error", "Failed to delete schedule: " + e.getMessage());
            showScheduleManagement(request, response, doctor);
        }
    }
    
    /**
     * Updates a full schedule (both morning and afternoon parts when spanning lunch)
     */
    private void updateFullSchedule(HttpServletRequest request, HttpServletResponse response, Doctor doctor)
            throws ServletException, IOException {
        try {
            // Debug logging
            System.out.println("Updating full schedule...");
            System.out.println("Parameters: " + request.getParameterMap().keySet());
            System.out.println("id param: " + request.getParameter("id"));
            System.out.println("afternoonId param: " + request.getParameter("afternoonId"));
            
            int morningId = Integer.parseInt(request.getParameter("id"));
            int afternoonId = Integer.parseInt(request.getParameter("afternoonId"));
            
            Schedule morningSchedule = scheduleFacade.find(morningId);
            Schedule afternoonSchedule = scheduleFacade.find(afternoonId);
            
            System.out.println("Morning schedule: " + (morningSchedule != null ? morningSchedule.getId() : "null"));
            System.out.println("Afternoon schedule: " + (afternoonSchedule != null ? afternoonSchedule.getId() : "null"));
            
            if (morningSchedule == null || afternoonSchedule == null || 
                morningSchedule.getDoctor().getId() != doctor.getId() || 
                afternoonSchedule.getDoctor().getId() != doctor.getId()) {
                request.setAttribute("error", "Schedule not found or you don't have permission to edit it.");
                showScheduleManagement(request, response, doctor);
                return;
            }
            
            String dayOfWeek = request.getParameter("dayOfWeek");
            String startTimeStr = request.getParameter("startTime");
            String endTimeStr = request.getParameter("endTime");
            
            // Validate inputs
            String error = validateScheduleInput(dayOfWeek, startTimeStr, endTimeStr);
            if (error != null) {
                request.setAttribute("error", error);
                request.setAttribute("schedule", morningSchedule);
                request.setAttribute("afternoonSchedule", afternoonSchedule);
                request.setAttribute("spansLunch", "true");
                request.getRequestDispatcher("/doctor/edit_schedule.jsp").forward(request, response);
                return;
            }
            
            // Convert string times to Time objects
            SimpleDateFormat sdf = new SimpleDateFormat("HH:mm");
            Time startTime = new Time(sdf.parse(startTimeStr).getTime());
            Time endTime = new Time(sdf.parse(endTimeStr).getTime());
            
            // Update morning schedule (before lunch)
            morningSchedule.setDayOfWeek(dayOfWeek);
            morningSchedule.setStartTime(startTime);
            // Always end at noon for morning part
            morningSchedule.setEndTime(new Time(sdf.parse("12:00").getTime()));
            
            // Update afternoon schedule (after lunch)
            afternoonSchedule.setDayOfWeek(dayOfWeek);
            // Always start at 1pm for afternoon part
            afternoonSchedule.setStartTime(new Time(sdf.parse("13:00").getTime()));
            afternoonSchedule.setEndTime(endTime);
            
            // Save both schedules
            scheduleFacade.edit(morningSchedule);
            scheduleFacade.edit(afternoonSchedule);
            
            request.setAttribute("success", "Schedule updated successfully.");
            showScheduleManagement(request, response, doctor);
            
        } catch (NumberFormatException e) {
            e.printStackTrace();
            request.setAttribute("error", "Invalid schedule ID: " + e.getMessage());
            showScheduleManagement(request, response, doctor);
        } catch (ParseException e) {
            e.printStackTrace();
            request.setAttribute("error", "Invalid time format: " + e.getMessage());
            showScheduleManagement(request, response, doctor);
        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Failed to update schedule: " + e.getMessage());
            showScheduleManagement(request, response, doctor);
        }
    }
    
    /**
     * Validates schedule input parameters
     * 
     * @param dayOfWeek Day of week
     * @param startTimeStr Start time string (HH:mm)
     * @param endTimeStr End time string (HH:mm)
     * @return Error message if validation fails, null if validation passes
     */
    private String validateScheduleInput(String dayOfWeek, String startTimeStr, String endTimeStr) {
        // Validate day of week
        if (dayOfWeek == null || dayOfWeek.isEmpty()) {
            return "Day of week is required.";
        }
        
        String[] validDays = {"Monday", "Tuesday", "Wednesday", "Thursday", "Friday"};
        boolean isDayValid = false;
        for (String day : validDays) {
            if (day.equals(dayOfWeek)) {
                isDayValid = true;
                break;
            }
        }
        
        if (!isDayValid) {
            return "Invalid day of week. Must be one of Monday, Tuesday, Wednesday, Thursday, or Friday.";
        }
        
        // Validate time format
        if (startTimeStr == null || startTimeStr.isEmpty()) {
            return "Start time is required.";
        }
        if (endTimeStr == null || endTimeStr.isEmpty()) {
            return "End time is required.";
        }
        
        try {
            // Convert to minutes for easier comparison
            SimpleDateFormat timeFormat = new SimpleDateFormat("HH:mm");
            
            java.util.Date startDate = timeFormat.parse(startTimeStr);
            java.util.Date endDate = timeFormat.parse(endTimeStr);
            java.util.Date lunchStartDate = timeFormat.parse("12:00");
            java.util.Date lunchEndDate = timeFormat.parse("13:00");
            
            long startMinutes = startDate.getTime() / (60 * 1000);
            long endMinutes = endDate.getTime() / (60 * 1000);
            long lunchStartMinutes = lunchStartDate.getTime() / (60 * 1000);
            long lunchEndMinutes = lunchEndDate.getTime() / (60 * 1000);
            
            // Clinic hours validation (8:00 to 18:00)
            java.util.Date clinicStartDate = timeFormat.parse("08:00");
            java.util.Date clinicEndDate = timeFormat.parse("18:00");
            long clinicStartMinutes = clinicStartDate.getTime() / (60 * 1000);
            long clinicEndMinutes = clinicEndDate.getTime() / (60 * 1000);
            
            if (startMinutes < clinicStartMinutes) {
                return "Start time cannot be earlier than clinic opening hours (8:00 AM).";
            }
            
            if (endMinutes > clinicEndMinutes) {
                return "End time cannot be later than clinic closing hours (6:00 PM).";
            }
            
            // End time must be after start time
            if (endMinutes <= startMinutes) {
                return "End time must be after start time.";
            }
            
            // Check if schedule overlaps with lunch break (12:00 - 13:00)
            boolean overlapsLunch = (startMinutes < lunchEndMinutes && endMinutes > lunchStartMinutes);
            
            // If schedule spans lunch break, we'll split it later during save, so validation passes
            if (overlapsLunch && (startMinutes >= lunchStartMinutes || endMinutes <= lunchEndMinutes)) {
                // Schedule only partially overlaps lunch - not allowed
                // Only full span of lunch break is allowed (for UI representation that will be split internally)
                return "Schedule cannot partially overlap with lunch break (12:00 PM - 1:00 PM). "
                    + "Either create a schedule that ends at 12:00 PM, starts at 1:00 PM, or spans the entire lunch break.";
            }
            
            return null; // Validation passed
            
        } catch (ParseException e) {
            return "Invalid time format. Please use HH:mm format.";
        }
    }
    
    /**
     * Checks if a schedule conflicts with existing schedules
     * 
     * @param doctorId Doctor ID
     * @param dayOfWeek Day of week
     * @param startTime Start time
     * @param endTime End time
     * @param excludeScheduleId Schedule ID to exclude from conflict check (for updates)
     * @return true if conflict exists, false otherwise
     */
    private boolean checkScheduleConflict(int doctorId, String dayOfWeek, Time startTime, Time endTime, int excludeScheduleId) {
        List<Schedule> existingSchedules = scheduleFacade.findByDoctorAndDay(doctorId, dayOfWeek);
        
        for (Schedule schedule : existingSchedules) {
            // Skip the schedule being updated
            if (schedule.getId() == excludeScheduleId) {
                continue;
            }
            
            // Check for overlap
            boolean overlaps = (startTime.before(schedule.getEndTime()) && endTime.after(schedule.getStartTime()));
            
            if (overlaps) {
                return true; // Conflict found
            }
        }
        
        return false; // No conflict
    }

    /**
     * Handles the HTTP <code>GET</code> method.
     *
     * @param request servlet request
     * @param response servlet response
     * @throws ServletException if a servlet-specific error occurs
     * @throws IOException if an I/O error occurs
     */
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processRequest(request, response);
    }

    /**
     * Handles the HTTP <code>POST</code> method.
     *
     * @param request servlet request
     * @param response servlet response
     * @throws ServletException if a servlet-specific error occurs
     * @throws IOException if an I/O error occurs
     */
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processRequest(request, response);
    }

    /**
     * Returns a short description of the servlet.
     *
     * @return a String containing servlet description
     */
    @Override
    public String getServletInfo() {
        return "Schedule management servlet for doctors";
    }
}
