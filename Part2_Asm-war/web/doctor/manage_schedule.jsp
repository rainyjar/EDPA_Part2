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
    
    List<Schedule> schedules = (List<Schedule>) request.getAttribute("schedules");
    List<ConsolidatedSchedule> consolidatedSchedules = (List<ConsolidatedSchedule>) request.getAttribute("consolidatedSchedules");
%>
<!DOCTYPE html>
<html lang="en">
    <head>
        <title>Manage Schedule - AMC Healthcare System</title>
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
            
            .schedule-table th, .schedule-table td {
                padding: 12px 15px;
                vertical-align: middle;
            }
            
            .action-btn {
                margin-right: 5px;
            }
            
            .add-schedule-card {
                margin-bottom: 30px;
                box-shadow: 0 4px 8px rgba(0,0,0,0.1);
                border-radius: 5px;
            }
            
            .add-schedule-card .card-header {
                background-color: #302a74;
                color: white;
                padding: 15px;
                border-radius: 5px 5px 0 0;
            }
            
            .add-schedule-card .card-body {
                padding: 20px;
            }
            
            .schedule-list-card {
                box-shadow: 0 4px 8px rgba(0,0,0,0.1);
                border-radius: 5px;
            }
            
            .schedule-list-card .card-header {
                background-color: #3f51b5;
                color: white;
                padding: 15px;
                border-radius: 5px 5px 0 0;
            }
            
            .schedule-list-card .card-body {
                padding: 20px;
            }
            
            .btn-add-schedule {
                background-color: #302a74;
                border-color: #302a74;
            }
            
            .btn-add-schedule:hover {
                background-color: #292374;
                border-color: #292374;
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
                            <span style="color:white">Manage Schedule</span>
                        </h1>
                        <p class="lead wow fadeInUp" data-wow-delay="0.2s" style="color: whitesmoke">
                            Set your available times for patient appointments. Note that the clinic operates Monday to Friday, and lunch break is from 12:00 PM to 1:00 PM.
                        </p>
                        <nav aria-label="breadcrumb" class="wow fadeInUp" data-wow-delay="0.3s">
                            <ol class="breadcrumb" style="background: transparent; margin: 0;">
                                <li class="breadcrumb-item">
                                    <a href="http://localhost:8080/Part2_Asm-war/DoctorHomepageServlet" style="color: rgba(255,255,255,0.8);">Dashboard</a> 
                                </li>
                                <li class="breadcrumb-item active" style="color: white;">Manage Schedule</li>
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
                        <% 
                            String error = (String) request.getAttribute("error");
                            if (error != null && !error.isEmpty()) { 
                        %>
                            <div class="alert alert-danger wow fadeInUp" data-wow-delay="0.2s" role="alert">
                                <i class="fa fa-exclamation-circle"></i> <%= error %>
                            </div>
                        <% 
                            }
                            
                            String success = (String) request.getAttribute("success");
                            if (success != null && !success.isEmpty()) { 
                        %>
                            <div class="alert alert-success wow fadeInUp" data-wow-delay="0.2s" role="alert">
                                <i class="fa fa-check-circle"></i> <%= success %>
                            </div>
                        <% } %>
                    </div>
                </div>
                
                <div class="row">
                    <!-- Add New Schedule Form -->
                    <div class="col-md-5">
                        <div class="add-schedule-card wow fadeInUp" data-wow-delay="0.4s">
                            <div class="card-header">
                                <h4 style="color: white;"><i class="fa fa-plus-circle"></i> Add New Schedule</h4>
                            </div>
                            <div class="card-body">
                                <form action="${pageContext.request.contextPath}/ScheduleServlet" method="post">
                                    <input type="hidden" name="action" value="add">
                                    
                                    <div class="form-group">
                                        <label for="dayOfWeek" class="control-label">Day of Week</label>
                                        <select class="form-control custom-select" id="dayOfWeek" name="dayOfWeek" required>
                                            <option value="">Select a day</option>
                                            <option value="Monday">Monday</option>
                                            <option value="Tuesday">Tuesday</option>
                                            <option value="Wednesday">Wednesday</option>
                                            <option value="Thursday">Thursday</option>
                                            <option value="Friday">Friday</option>
                                        </select>
                                    </div>
                                    
                                    <div class="form-group">
                                        <label for="startTime" class="control-label">Start Time</label>
                                        <div class="time-note">Between 9:00 AM - 12:00 PM or 1:00 PM - 5:00 PM</div>
                                        <select class="form-control custom-select" id="startTime" name="startTime" required>
                                            <option value="">Select start time</option>
                                            <option value="09:00">09:00 AM</option>
                                            <option value="09:30">09:30 AM</option>
                                            <option value="10:00">10:00 AM</option>
                                            <option value="10:30">10:30 AM</option>
                                            <option value="11:00">11:00 AM</option>
                                            <option value="11:30">11:30 AM</option>
                                            <option value="13:00">01:00 PM</option>
                                            <option value="13:30">01:30 PM</option>
                                            <option value="14:00">02:00 PM</option>
                                            <option value="14:30">02:30 PM</option>
                                            <option value="15:00">03:00 PM</option>
                                            <option value="15:30">03:30 PM</option>
                                            <option value="16:00">04:00 PM</option>
                                            <option value="16:30">04:30 PM</option>
                                        </select>
                                    </div>
                                    
                                    <div class="form-group">
                                        <label for="endTime" class="control-label">End Time</label>
                                        <div class="time-note">Must be after start time and before 5:00 PM</div>
                                        <select class="form-control custom-select" id="endTime" name="endTime" required>
                                            <option value="">Select end time</option>
                                            <option value="09:30">09:30 AM</option>
                                            <option value="10:00">10:00 AM</option>
                                            <option value="10:30">10:30 AM</option>
                                            <option value="11:00">11:00 AM</option>
                                            <option value="11:30">11:30 AM</option>
                                            <option value="12:00">12:00 PM</option>
                                            <option value="13:30">01:30 PM</option>
                                            <option value="14:00">02:00 PM</option>
                                            <option value="14:30">02:30 PM</option>
                                            <option value="15:00">03:00 PM</option>
                                            <option value="15:30">03:30 PM</option>
                                            <option value="16:00">04:00 PM</option>
                                            <option value="16:30">04:30 PM</option>
                                            <option value="17:00">05:00 PM</option>
                                        </select>
                                    </div>
                                    
                                    <button type="submit" class="btn btn-primary btn-add-schedule">
                                        <i class="fa fa-plus"></i> Add Schedule
                                    </button>
                                </form>
                            </div>
                        </div>
                    </div>
                    
                    <!-- Current Schedules -->
                    <div class="col-md-7">
                        <div class="schedule-list-card wow fadeInUp" data-wow-delay="0.6s">
                            <div class="card-header">
                                <h4 style="color: white;"><i class="fa fa-list"></i> Your Current Schedules</h4>
                            </div>
                            <div class="card-body">
                                <% if (schedules == null || schedules.isEmpty()) { %>
                                    <div class="text-center py-5">
                                        <i class="fa fa-calendar-o fa-4x text-muted mb-3"></i>
                                        <p class="text-muted">You don't have any schedules yet. Add your availability using the form.</p>
                                    </div>
                                <% } else { %>
                                    <div class="table-responsive">
                                        <table class="table table-striped table-hover schedule-table">
                                            <thead>
                                                <tr>
                                                    <th>Day</th>
                                                    <th>Time</th>
                                                    <th>Actions</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                <% 
                                                    if (consolidatedSchedules != null) {
                                                        for (ScheduleHelper.ConsolidatedSchedule schedule : consolidatedSchedules) {
                                                %>
                                                    <tr>
                                                        <td><%= schedule.getDayOfWeek() %></td>
                                                        <td><%= schedule.getDisplayText() %></td>
                                                        <td>
                                                        <% if (!schedule.isSpansLunchBreak()) { %>
                                                            <a href="${pageContext.request.contextPath}/ScheduleServlet?action=edit&id=<%= schedule.getFirstSchedule().getId() %>" class="btn btn-sm btn-primary action-btn">
                                                                <i class="fa fa-edit"></i> Edit
                                                            </a>
                                                            <a href="${pageContext.request.contextPath}/ScheduleServlet?action=delete&id=<%= schedule.getFirstSchedule().getId() %>" class="btn btn-sm btn-danger action-btn" onclick="return confirm('Are you sure you want to delete this schedule?')">
                                                                <i class="fa fa-trash"></i> Delete
                                                            </a>
                                                        <% } else { 
                                                            int morningId = schedule.getActualSchedules().get(0).getId();
                                                            int afternoonId = schedule.getActualSchedules().get(1).getId();
                                                        %>
                                                            <a href="${pageContext.request.contextPath}/ScheduleServlet?action=edit&id=<%= morningId %>&spansLunch=true" class="btn btn-sm btn-primary action-btn">
                                                                <i class="fa fa-edit"></i> Edit Schedule
                                                            </a>
                                                            <a href="javascript:void(0)" class="btn btn-sm btn-danger action-btn" onclick="deleteFullSchedule(<%= morningId %>, <%= afternoonId %>)">
                                                                <i class="fa fa-trash"></i> Delete Schedule
                                                            </a>
                                                        <% } %>
                                                        </td>
                                                    </tr>
                                                <% 
                                                        }
                                                    }
                                                %>
                                                </tbody>
                                            </table>
                                        </div>
                                <% } %>
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
                
                // Add options for spanning lunch
                startTimeSelect.addEventListener('change', function() {
                    if (!startTimeSelect.value) {
                        return;
                    }
                    
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
                    
                    // Allow spanning lunch for morning start times
                    const allowSpanLunch = startTime < "12:00";
                    
                    // Add only valid end times (after start time)
                    allEndTimes.forEach(function(time) {
                        // Skip lunch hour endings unless we allow spanning
                        if (time.value > startTime && (allowSpanLunch || !(time.value > "12:00" && time.value < "13:00"))) {
                            const option = document.createElement('option');
                            option.value = time.value;
                            option.textContent = time.display;
                            
                            // Mark afternoon times for morning starts
                            if (startTime < "12:00" && time.value > "13:00") {
                                option.textContent += " (spans lunch break)";
                            }
                            
                            endTimeSelect.appendChild(option);
                        }
                    });
                });
                
                
                // Prevent partial overlapping with lunch hours (12:00 - 13:00)
                const form = document.querySelector('form');
                form.addEventListener('submit', function(event) {
                    const startTime = startTimeSelect.value;
                    const endTime = endTimeSelect.value;
                    
                    if (isPartialLunchOverlap(startTime, endTime)) {
                        event.preventDefault();
                        alert('Schedule cannot partially overlap with lunch break (12:00 PM - 1:00 PM). Either end before 12:00 PM, start after 1:00 PM, or span the entire lunch break.');
                    }
                });
                
                function isPartialLunchOverlap(start, end) {
                    const lunchStart = '12:00';
                    const lunchEnd = '13:00';
                    
                    // Check if schedule overlaps lunch but doesn't span it completely
                    const overlapsLunch = (start < lunchEnd && end > lunchStart);
                    const spansLunchCompletely = (start <= lunchStart && end >= lunchEnd);
                    
                    // Return true if overlaps lunch but doesn't span it completely
                    return overlapsLunch && !spansLunchCompletely;
                }
                
                // Function to delete both morning and afternoon segments of a schedule
                window.deleteFullSchedule = function(morningId, afternoonId) {
                    if (confirm('Are you sure you want to delete this entire schedule?')) {
                        // Create a form to submit the delete request for both segments
                        const form = document.createElement('form');
                        form.method = 'POST';
                        form.action = '${pageContext.request.contextPath}/ScheduleServlet';
                        
                        // Add action parameter
                        const actionInput = document.createElement('input');
                        actionInput.type = 'hidden';
                        actionInput.name = 'action';
                        actionInput.value = 'deleteFull';
                        form.appendChild(actionInput);
                        
                        // Add morningId parameter
                        const morningInput = document.createElement('input');
                        morningInput.type = 'hidden';
                        morningInput.name = 'morningId';
                        morningInput.value = morningId;
                        form.appendChild(morningInput);
                        
                        // Add afternoonId parameter
                        const afternoonInput = document.createElement('input');
                        afternoonInput.type = 'hidden';
                        afternoonInput.name = 'afternoonId';
                        afternoonInput.value = afternoonId;
                        form.appendChild(afternoonInput);
                        
                        // Append the form to the body and submit it
                        document.body.appendChild(form);
                        form.submit();
                    }
                };
            });
        </script>
    </body>
</html>
