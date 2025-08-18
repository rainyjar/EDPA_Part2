<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ page import="model.Doctor" %>
<%@ page import="model.Schedule" %>
<%@ page import="model.ScheduleHelper" %>
<%@ page import="model.ScheduleHelper.ConsolidatedSchedule" %>
<%@ page import="java.util.List" %>
<%
    Doctor doctor = (Doctor) session.getAttribute("doctor");
    if (doctor == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    
    Schedule schedule = (Schedule) request.getAttribute("schedule");
    Schedule afternoonSchedule = (Schedule) request.getAttribute("afternoonSchedule");
    boolean spansLunch = request.getParameter("spansLunch") != null && request.getParameter("spansLunch").equals("true");
    
    System.out.println("JSP - spansLunch: " + spansLunch);
    System.out.println("JSP - afternoonSchedule: " + (afternoonSchedule != null ? afternoonSchedule.getId() : "null"));
    
    if (schedule == null) {
        response.sendRedirect(request.getContextPath() + "/ScheduleServlet");
        return;
    }
%>
<!DOCTYPE html>
<html lang="en">
    <head>
        <title>Edit Schedule - AMC Healthcare System</title>
        <%@ include file="/includes/head.jsp" %>
        <link rel="stylesheet" href="${pageContext.request.contextPath}/css/manager-homepage.css">
        <link rel="stylesheet" href="${pageContext.request.contextPath}/css/manage-staff.css">
        
        <style>
            .time-input {
                padding: 10px;
                border-radius: 4px;
                border: 1px solid #ddd;
                width: 100%;
            }
            
            .edit-schedule-card {
                box-shadow: 0 4px 8px rgba(0,0,0,0.1);
                border-radius: 5px;
                margin-top: 20px;
                margin-bottom: 30px;
            }
            
            .edit-schedule-card .card-header {
                background-color: #3f51b5;
                color: white;
                padding: 15px;
                border-radius: 5px 5px 0 0;
            }
            
            .edit-schedule-card .card-body {
                padding: 20px;
            }

            .add-schedule-card .card-header {
                background-color: #302a74; 
                color: white;
                padding: 15px;
                border-radius: 5px 5px 0 0;
            }
            
            .btn-update {
                background-color: #302a74;
                border-color: #302a74;
            }
            
            .btn-update:hover {
                background-color: #292374;
                border-color: #292374;
            }
            
            .btn-cancel {
                background-color: #6c757d;
                border-color: #6c757d;
            }
            
            .time-note {
                font-size: 12px;
                color: #666;
                margin-bottom: 5px;
            }
            
            @media (max-width: 768px) {
                .card {
                    margin-bottom: 20px;
                }
            }
        </style>
    </head>
    <body id="top">
        <%@ include file="/includes/header.jsp" %>
        <%@ include file="/includes/navbar.jsp" %>

        <!-- PAGE HEADER -->
        <section class="page-header">
            <div class="container">
                <div class="row">
                    <div class="col-md-12">
                        <h1 class="wow fadeInUp">
                            <i class="fa fa-calendar-check-o" style="color:white"></i>
                            <span style="color:white">Edit Schedule</span>
                        </h1>
                        <p class="lead wow fadeInUp" data-wow-delay="0.2s" style="color: whitesmoke">
                            Update your availability schedule for patient appointments.
                        </p>
                        <nav aria-label="breadcrumb" class="wow fadeInUp" data-wow-delay="0.3s">
                            <ol class="breadcrumb" style="background: transparent; margin: 0;">
                                <li class="breadcrumb-item">
                                    <a href="http://localhost:8080/Part2_Asm-war/DoctorHomepageServlet" style="color: rgba(255,255,255,0.8);">Dashboard</a> 
                                </li>
                                <li class="breadcrumb-item active" style="color: white;">Edit Schedule</li>
                            </ol>
                        </nav>
                    </div>
                </div>
            </div>
        </section>
               
        <!-- MAIN CONTENT -->
        <section>
            <div class="container">
                <div class="row">
                    <div class="col-md-12">
                        <c:if test="${not empty error}">
                            <div class="alert alert-danger wow fadeInUp" data-wow-delay="0.2s" role="alert">
                                <i class="fa fa-exclamation-circle"></i> ${error}
                            </div>
                        </c:if>
                    </div>
                </div>
                
                <div class="row">
                    <div class="col-md-8 offset-md-2">
                        <div class="edit-schedule-card wow fadeInUp" data-wow-delay="0.4s">
                            <div class="card-header">
                                <h4 style="color: white;"><i class="fa fa-calendar-plus-o"></i> Update Schedule</h4>
                            </div>
                            <div class="card-body">
                                <form action="${pageContext.request.contextPath}/ScheduleServlet" method="post">
                                    <input type="hidden" name="action" value="<%= spansLunch ? "updateFull" : "update" %>">
                                    <input type="hidden" name="id" value="<%= schedule.getId() %>">
                                    <% if (spansLunch && afternoonSchedule != null) { %>
                                        <input type="hidden" name="afternoonId" value="<%= afternoonSchedule.getId() %>">
                                    <% } %>
                                    <input type="hidden" name="spansLunch" value="<%= spansLunch %>">
                                    
                                    <div class="form-group">
                                        <label for="dayOfWeek" class="control-label">Day of Week</label>
                                        <select class="form-control custom-select" id="dayOfWeek" name="dayOfWeek" required>
                                            <option value="">Select a day</option>
                                            <option value="Monday" <%= schedule.getDayOfWeek().equals("Monday") ? "selected" : "" %>>Monday</option>
                                            <option value="Tuesday" <%= schedule.getDayOfWeek().equals("Tuesday") ? "selected" : "" %>>Tuesday</option>
                                            <option value="Wednesday" <%= schedule.getDayOfWeek().equals("Wednesday") ? "selected" : "" %>>Wednesday</option>
                                            <option value="Thursday" <%= schedule.getDayOfWeek().equals("Thursday") ? "selected" : "" %>>Thursday</option>
                                            <option value="Friday" <%= schedule.getDayOfWeek().equals("Friday") ? "selected" : "" %>>Friday</option>
                                        </select>
                                    </div>
                                    
                                    <div class="form-group">
                                        <label for="startTime" class="control-label">Start Time</label>
                                        <div class="time-note">Between 9:00 AM - 12:00 PM or 1:00 PM - 5:00 PM</div>
                                        <select class="form-control custom-select" id="startTime" name="startTime" required>
                                            <option value="">Select start time</option>
                                            <option value="09:00" <%= schedule.getStartTime().toString().substring(0, 5).equals("09:00") ? "selected" : "" %>>09:00 AM</option>
                                            <option value="09:30" <%= schedule.getStartTime().toString().substring(0, 5).equals("09:30") ? "selected" : "" %>>09:30 AM</option>
                                            <option value="10:00" <%= schedule.getStartTime().toString().substring(0, 5).equals("10:00") ? "selected" : "" %>>10:00 AM</option>
                                            <option value="10:30" <%= schedule.getStartTime().toString().substring(0, 5).equals("10:30") ? "selected" : "" %>>10:30 AM</option>
                                            <option value="11:00" <%= schedule.getStartTime().toString().substring(0, 5).equals("11:00") ? "selected" : "" %>>11:00 AM</option>
                                            <option value="11:30" <%= schedule.getStartTime().toString().substring(0, 5).equals("11:30") ? "selected" : "" %>>11:30 AM</option>
                                            <option value="13:00" <%= schedule.getStartTime().toString().substring(0, 5).equals("13:00") ? "selected" : "" %>>01:00 PM</option>
                                            <option value="13:30" <%= schedule.getStartTime().toString().substring(0, 5).equals("13:30") ? "selected" : "" %>>01:30 PM</option>
                                            <option value="14:00" <%= schedule.getStartTime().toString().substring(0, 5).equals("14:00") ? "selected" : "" %>>02:00 PM</option>
                                            <option value="14:30" <%= schedule.getStartTime().toString().substring(0, 5).equals("14:30") ? "selected" : "" %>>02:30 PM</option>
                                            <option value="15:00" <%= schedule.getStartTime().toString().substring(0, 5).equals("15:00") ? "selected" : "" %>>03:00 PM</option>
                                            <option value="15:30" <%= schedule.getStartTime().toString().substring(0, 5).equals("15:30") ? "selected" : "" %>>03:30 PM</option>
                                            <option value="16:00" <%= schedule.getStartTime().toString().substring(0, 5).equals("16:00") ? "selected" : "" %>>04:00 PM</option>
                                            <option value="16:30" <%= schedule.getStartTime().toString().substring(0, 5).equals("16:30") ? "selected" : "" %>>04:30 PM</option>
                                        </select>
                                    </div>
                                    
                                    <div class="form-group">
                                        <label for="endTime" class="control-label">End Time</label>
                                        <div class="time-note">Must be after start time and before 5:00 PM</div>
                                        <select class="form-control custom-select" id="endTime" name="endTime" required>
                                            <option value="">Select end time</option>
                                            <option value="09:30" <%= !spansLunch && schedule.getEndTime().toString().substring(0, 5).equals("09:30") ? "selected" : "" %>>09:30 AM</option>
                                            <option value="10:00" <%= !spansLunch && schedule.getEndTime().toString().substring(0, 5).equals("10:00") ? "selected" : "" %>>10:00 AM</option>
                                            <option value="10:30" <%= !spansLunch && schedule.getEndTime().toString().substring(0, 5).equals("10:30") ? "selected" : "" %>>10:30 AM</option>
                                            <option value="11:00" <%= !spansLunch && schedule.getEndTime().toString().substring(0, 5).equals("11:00") ? "selected" : "" %>>11:00 AM</option>
                                            <option value="11:30" <%= !spansLunch && schedule.getEndTime().toString().substring(0, 5).equals("11:30") ? "selected" : "" %>>11:30 AM</option>
                                            <option value="12:00" <%= !spansLunch && schedule.getEndTime().toString().substring(0, 5).equals("12:00") ? "selected" : "" %>>12:00 PM</option>
                                            <option value="13:30" <%= !spansLunch && schedule.getEndTime().toString().substring(0, 5).equals("13:30") ? "selected" : "" %>>01:30 PM</option>
                                            <option value="14:00" <%= !spansLunch && schedule.getEndTime().toString().substring(0, 5).equals("14:00") ? "selected" : "" %>>02:00 PM</option>
                                            <option value="14:30" <%= !spansLunch && schedule.getEndTime().toString().substring(0, 5).equals("14:30") ? "selected" : "" %>>02:30 PM</option>
                                            <option value="15:00" <%= !spansLunch && schedule.getEndTime().toString().substring(0, 5).equals("15:00") ? "selected" : "" %>>03:00 PM</option>
                                            <option value="15:30" <%= !spansLunch && schedule.getEndTime().toString().substring(0, 5).equals("15:30") ? "selected" : "" %>>03:30 PM</option>
                                            <option value="16:00" <%= !spansLunch && schedule.getEndTime().toString().substring(0, 5).equals("16:00") ? "selected" : "" %>>04:00 PM</option>
                                            <option value="16:30" <%= !spansLunch && schedule.getEndTime().toString().substring(0, 5).equals("16:30") ? "selected" : "" %>>04:30 PM</option>
                                            <option value="17:00" <%= !spansLunch && schedule.getEndTime().toString().substring(0, 5).equals("17:00") ? "selected" : "" %>>05:00 PM</option>
                                            
                                            <% if (spansLunch && afternoonSchedule != null) { %>
                                                <option value="14:00" <%= afternoonSchedule.getEndTime().toString().substring(0, 5).equals("14:00") ? "selected" : "" %>>02:00 PM (spans lunch)</option>
                                                <option value="14:30" <%= afternoonSchedule.getEndTime().toString().substring(0, 5).equals("14:30") ? "selected" : "" %>>02:30 PM (spans lunch)</option>
                                                <option value="15:00" <%= afternoonSchedule.getEndTime().toString().substring(0, 5).equals("15:00") ? "selected" : "" %>>03:00 PM (spans lunch)</option>
                                                <option value="15:30" <%= afternoonSchedule.getEndTime().toString().substring(0, 5).equals("15:30") ? "selected" : "" %>>03:30 PM (spans lunch)</option>
                                                <option value="16:00" <%= afternoonSchedule.getEndTime().toString().substring(0, 5).equals("16:00") ? "selected" : "" %>>04:00 PM (spans lunch)</option>
                                                <option value="16:30" <%= afternoonSchedule.getEndTime().toString().substring(0, 5).equals("16:30") ? "selected" : "" %>>04:30 PM (spans lunch)</option>
                                                <option value="17:00" <%= afternoonSchedule.getEndTime().toString().substring(0, 5).equals("17:00") ? "selected" : "" %>>05:00 PM (spans lunch)</option>
                                            <% } %>
                                        </select>
                                    </div>
                                    
                                    <div class="form-group" style="margin-top: 20px;">
                                        <button type="submit" class="btn btn-primary btn-update">
                                            <i class="fa fa-check"></i> Update Schedule
                                        </button>
                                        <a href="${pageContext.request.contextPath}/ScheduleServlet" class="btn btn-secondary btn-cancel">
                                            <i class="fa fa-times"></i> Cancel
                                        </a>
                                    </div>
                                </form>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </section>
        
        <!-- FOOTER -->
        <%@ include file="/includes/footer.jsp" %>
        <%@ include file="/includes/scripts.jsp" %>
        
        <script>
            // Client-side validation for time inputs
            document.addEventListener('DOMContentLoaded', function() {
                const startTimeSelect = document.getElementById('startTime');
                const endTimeSelect = document.getElementById('endTime');
                
                // Ensure end time is after start time
                startTimeSelect.addEventListener('change', function() {
                    if (!startTimeSelect.value) {
                        return;
                    }
                    
                    // Store the currently selected end time if it exists
                    const currentEndTime = endTimeSelect.value;
                    
                    // Reset end time options
                    endTimeSelect.innerHTML = '<option value="">Select end time</option>';
                    
                    // Get selected start time
                    const startTime = startTimeSelect.value;
                    
                    // Define all possible end times
                    const allEndTimes = [
                        { value: "09:30", display: "09:30 AM" },
                        { value: "10:00", display: "10:00 AM" },
                        { value: "10:30", display: "10:30 AM" },
                        { value: "11:00", display: "11:00 AM" },
                        { value: "11:30", display: "11:30 AM" },
                        { value: "12:00", display: "12:00 PM" },
                        { value: "13:30", display: "01:30 PM" },
                        { value: "14:00", display: "02:00 PM" },
                        { value: "14:30", display: "02:30 PM" },
                        { value: "15:00", display: "03:00 PM" },
                        { value: "15:30", display: "03:30 PM" },
                        { value: "16:00", display: "04:00 PM" },
                        { value: "16:30", display: "04:30 PM" },
                        { value: "17:00", display: "05:00 PM" }
                    ];
                    
                    // Add only valid end times (after start time)
                    allEndTimes.forEach(function(time) {
                        if (time.value > startTime) {
                            const option = document.createElement('option');
                            option.value = time.value;
                            option.textContent = time.display;
                            
                            // Re-select the previously selected end time if it's still valid
                            if (time.value === currentEndTime) {
                                option.selected = true;
                            }
                            
                            endTimeSelect.appendChild(option);
                        }
                    });
                });
                
                // Initialize end time options on page load based on selected start time
                if (startTimeSelect.value) {
                    startTimeSelect.dispatchEvent(new Event('change'));
                }
                
                // Prevent selection during lunch hours (12:00 - 13:00) only for non-spanning schedules
                const form = document.querySelector('form');
                form.addEventListener('submit', function(event) {
                    // Get the value of the spansLunch hidden input
                    const spansLunch = document.querySelector('input[name="spansLunch"]').value === 'true';
                    
                    // Only perform this validation if the schedule doesn't intentionally span lunch
                    if (!spansLunch) {
                        const startTime = startTimeSelect.value;
                        const endTime = endTimeSelect.value;
                        
                        if (isLunchOverlap(startTime, endTime)) {
                            event.preventDefault();
                            alert('Schedule cannot overlap with lunch break (12:00 PM - 1:00 PM). If you want to schedule across lunch, please create a schedule that spans lunch.');
                        }
                    }
                });
                
                function isLunchOverlap(start, end) {
                    const lunchStart = '12:00';
                    const lunchEnd = '13:00';
                    
                    // Check if schedule overlaps lunch
                    return (start < lunchEnd && end > lunchStart);
                }
            });
        </script>
    </body>
</html>
