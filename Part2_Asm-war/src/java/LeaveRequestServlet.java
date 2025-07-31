/*
 * LeaveRequestServlet - Handles doctor unavailability management
 * Allows doctors to submit their unavailable dates and times
 * Automatically triggers post-booking validation when unavailability is added
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
import model.Doctor;
import model.DoctorFacade;
import model.LeaveRequest;
import model.LeaveRequestFacade;

@WebServlet(urlPatterns = {"/ScheduleUnavailableServlet"})
public class LeaveRequestServlet extends HttpServlet {

    @EJB
    private LeaveRequestFacade scheduleUnavailableFacade;
    
    @EJB
    private DoctorFacade doctorFacade;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        String action = request.getParameter("action");
        
        if ("manage".equals(action)) {
            handleManageUnavailability(request, response);
        } else if ("view".equals(action)) {
            handleViewUnavailability(request, response);
        } else {
            // Default: show manage form
            handleManageUnavailability(request, response);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        String action = request.getParameter("action");
        
        if ("add".equals(action)) {
            handleAddUnavailability(request, response);
        } else if ("delete".equals(action)) {
            handleDeleteUnavailability(request, response);
        } else {
            response.sendRedirect(request.getContextPath() + "/ScheduleUnavailableServlet?action=manage");
        }
    }
    
    /**
     * Handle manage unavailability page - show form and existing unavailabilities
     */
    private void handleManageUnavailability(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        try {
            // Check if doctor is logged in (assuming doctor session management exists)
            HttpSession session = request.getSession();
            Doctor loggedInDoctor = (Doctor) session.getAttribute("doctor");
            
            if (loggedInDoctor == null) {
                response.sendRedirect(request.getContextPath() + "/login.jsp");
                return;
            }
            
            // Load doctor's existing unavailabilities
            List<LeaveRequest> unavailabilities = scheduleUnavailableFacade.findByDoctor(loggedInDoctor.getId());
            
            request.setAttribute("unavailabilities", unavailabilities);
            request.setAttribute("doctor", loggedInDoctor);
            
            // Forward to JSP (you'll need to create this)
            request.getRequestDispatcher("/doctor/manage_unavailability.jsp").forward(request, response);
            
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + "/doctor/doctor_homepage.jsp?error=system_error");
        }
    }
    
    /**
     * Handle view unavailability - for managers or counter staff
     */
    private void handleViewUnavailability(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        try {
            // Get all unavailabilities for all doctors (manager view)
            List<LeaveRequest> allUnavailabilities = scheduleUnavailableFacade.findAll();
            List<Doctor> doctorList = doctorFacade.findAll();
            
            request.setAttribute("unavailabilities", allUnavailabilities);
            request.setAttribute("doctorList", doctorList);
            
            // Forward to manager JSP (you'll need to create this)
            request.getRequestDispatcher("/manager/view_unavailability.jsp").forward(request, response);
            
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + "/manager/manager_homepage.jsp?error=system_error");
        }
    }
    
    /**
     * Handle adding new unavailability and trigger post-booking validation
     */
    private void handleAddUnavailability(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        try {
            // Check if doctor is logged in
            HttpSession session = request.getSession();
            Doctor loggedInDoctor = (Doctor) session.getAttribute("doctor");
            
            if (loggedInDoctor == null) {
                response.sendRedirect(request.getContextPath() + "/login.jsp");
                return;
            }
            
            // Get form parameters
            String unavailableDateStr = request.getParameter("unavailable_date");
            String startTimeStr = request.getParameter("start_time");
            String endTimeStr = request.getParameter("end_time");
            String reason = request.getParameter("reason");
            String status = request.getParameter("status");
            
            // Validate parameters
            if (unavailableDateStr == null || unavailableDateStr.trim().isEmpty() ||
                startTimeStr == null || startTimeStr.trim().isEmpty() ||
                endTimeStr == null || endTimeStr.trim().isEmpty()) {
                response.sendRedirect(request.getContextPath() + "/ScheduleUnavailableServlet?action=manage&error=missing_data");
                return;
            }
            
            // Parse date and times
            Date unavailableDate = new SimpleDateFormat("yyyy-MM-dd").parse(unavailableDateStr);
            Time startTime = new Time(new SimpleDateFormat("HH:mm").parse(startTimeStr).getTime());
            Time endTime = new Time(new SimpleDateFormat("HH:mm").parse(endTimeStr).getTime());
            
            // Validate that end time is after start time
            if (endTime.compareTo(startTime) <= 0) {
                response.sendRedirect(request.getContextPath() + "/ScheduleUnavailableServlet?action=manage&error=invalid_time_range");
                return;
            }
            
            // Check for overlapping unavailabilities
            List<LeaveRequest> overlapping = scheduleUnavailableFacade.findOverlappingUnavailabilities(
                loggedInDoctor.getId(), unavailableDate, startTime, endTime);
            
            if (!overlapping.isEmpty()) {
                response.sendRedirect(request.getContextPath() + "/ScheduleUnavailableServlet?action=manage&error=overlapping_unavailability");
                return;
            }
            
            // Create new unavailability record
            LeaveRequest newUnavailability = new LeaveRequest(
                unavailableDate, startTime, endTime, status, reason, loggedInDoctor);
            
            // Save to database
            scheduleUnavailableFacade.create(newUnavailability);
            
            System.out.println("=== NEW UNAVAILABILITY CREATED ===");
            System.out.println("Doctor: " + loggedInDoctor.getName());
            System.out.println("Date: " + unavailableDate);
            System.out.println("Time: " + startTime + " - " + endTime);
            System.out.println("Reason: " + reason);
            System.out.println("================================");
            
            // CRITICAL: Trigger post-booking validation to update affected appointments
            AppointmentServlet appointmentServlet = new AppointmentServlet();
            int affectedAppointments = appointmentServlet.handlePostBookingValidation(newUnavailability);
            
            if (affectedAppointments > 0) {
                System.out.println("🚨 " + affectedAppointments + " appointments automatically updated to 'Reschedule Required'");
                response.sendRedirect(request.getContextPath() + "/ScheduleUnavailableServlet?action=manage&success=unavailability_added&affected=" + affectedAppointments);
            } else {
                System.out.println("✅ No appointments affected by this unavailability");
                response.sendRedirect(request.getContextPath() + "/ScheduleUnavailableServlet?action=manage&success=unavailability_added");
            }
            
        } catch (ParseException e) {
            response.sendRedirect(request.getContextPath() + "/ScheduleUnavailableServlet?action=manage&error=invalid_datetime");
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + "/ScheduleUnavailableServlet?action=manage&error=system_error");
        }
    }
    
    /**
     * Handle deleting unavailability
     */
    private void handleDeleteUnavailability(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        try {
            // Check if doctor is logged in
            HttpSession session = request.getSession();
            Doctor loggedInDoctor = (Doctor) session.getAttribute("doctor");
            
            if (loggedInDoctor == null) {
                response.sendRedirect(request.getContextPath() + "/login.jsp");
                return;
            }
            
            String unavailabilityIdStr = request.getParameter("unavailability_id");
            if (unavailabilityIdStr == null || unavailabilityIdStr.trim().isEmpty()) {
                response.sendRedirect(request.getContextPath() + "/ScheduleUnavailableServlet?action=manage&error=invalid_id");
                return;
            }
            
            int unavailabilityId = Integer.parseInt(unavailabilityIdStr);
            LeaveRequest unavailability = scheduleUnavailableFacade.find(unavailabilityId);
            
            if (unavailability == null) {
                response.sendRedirect(request.getContextPath() + "/ScheduleUnavailableServlet?action=manage&error=not_found");
                return;
            }
            
            // Verify ownership
            if (unavailability.getDoctor().getId() != loggedInDoctor.getId()) {
                response.sendRedirect(request.getContextPath() + "/ScheduleUnavailableServlet?action=manage&error=unauthorized");
                return;
            }
            
            // Delete the unavailability
            scheduleUnavailableFacade.remove(unavailability);
            
            System.out.println("=== UNAVAILABILITY DELETED ===");
            System.out.println("Doctor: " + loggedInDoctor.getName());
            System.out.println("Date: " + unavailability.getUnavailableDate());
            System.out.println("Time: " + unavailability.getStartTime() + " - " + unavailability.getEndTime());
            System.out.println("===============================");
            
            response.sendRedirect(request.getContextPath() + "/ScheduleUnavailableServlet?action=manage&success=unavailability_deleted");
            
        } catch (NumberFormatException e) {
            response.sendRedirect(request.getContextPath() + "/ScheduleUnavailableServlet?action=manage&error=invalid_id");
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + "/ScheduleUnavailableServlet?action=manage&error=system_error");
        }
    }
}
