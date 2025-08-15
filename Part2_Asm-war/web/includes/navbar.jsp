<%--<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>--%>
<%
    // Get current page name for active menu highlighting
    String currentPage = request.getRequestURI();
    String pageName = currentPage.substring(currentPage.lastIndexOf("/") + 1);
%>
<!-- MENU -->
<!--<section class="navbar navbar-default navbar-static-top role="navigation">-->
<section class="navbar navbar-default navbar-static-top" role="navigation">
    <div class="container">

        <div class="navbar-header">
            <button class="navbar-toggle" data-toggle="collapse" data-target=".navbar-collapse">
                <span class="icon icon-bar"></span>
                <span class="icon icon-bar"></span>
                <span class="icon icon-bar"></span>
            </button>

            <!--lOGO TEXT HERE--> 
            <a href="<%= request.getContextPath()%>/CustomerHomepageServlet" class="img-responsive">
                <img src="<%= request.getContextPath()%>/images/amc_logo.png" alt="APU Medical Center Logo">
            </a>
        </div>

        <!--MENU LINKS--> 
        <div class="collapse navbar-collapse">
            <ul class="nav navbar-nav navbar-right">
                <% if (session.getAttribute("doctor") != null) { %>
                    <!-- Doctor Navigation -->
                    <li <%= request.getRequestURI().contains("doctor_homepage.jsp") ? "class='active'" : ""%>>
                        <a href="<%= request.getContextPath()%>/DoctorHomepageServlet?action=dashboard">Dashboard</a>
                    </li>
                    <li <%= request.getServletPath().contains("TreatmentServlet") ? "class='active'" : ""%>>
                        <a href="<%= request.getContextPath()%>/TreatmentServlet?action=myTasks">My Tasks</a>
                    </li>
                     <li <%= request.getServletPath().contains("ScheduleServlet") ? "class='active'" : ""%>>
                        <a href="<%= request.getContextPath()%>/ScheduleServlet?action=manage">My Schedule</a>
                    </li>
                    <li <%= request.getServletPath().contains("DoctorServlet") ? "class='active'" : ""%>>
                        <a href="<%= request.getContextPath()%>/DoctorServlet?action=viewAppointmentHistory">View Appointments</a>
                    </li>
                    <li <%= request.getServletPath().contains("Profile") ? "class='active'" : ""%>>
                        <a href="<%= request.getContextPath()%>/Profile">Profile</a>
                    </li>
                    <li class="appointment-btn">
                        <a href="<%= request.getContextPath()%>/Login?action=logout">Logout</a>
                    </li>
                <% } else if (session.getAttribute("staff") != null) { %>
                    <!-- Counter Staff Navigation -->
                    <li <%= request.getRequestURI().contains("counter_homepage.jsp") ? "class='active'" : ""%>>
                        <a href="<%= request.getContextPath()%>/CounterStaffServletJam?action=dashboard">Dashboard</a>
                    </li>
                    <li <%= request.getServletPath().contains("AppointmentServlet") ? "class='active'" : ""%>>
                        <a href="<%= request.getContextPath()%>/AppointmentServlet?action=manage">Manage Appointments</a>
                    </li>
                    <li <%= request.getServletPath().contains("CustomerServlet") ? "class='active'" : ""%>>
                        <a href="<%= request.getContextPath()%>/CustomerServlet?action=viewAll">Manage Customers</a>
                    </li>
                    <li <%= request.getServletPath().contains("CounterStaffServletJam") ? "class='active'" : ""%>>
                        <a href="<%= request.getContextPath()%>/CounterStaffServletJam?action=viewRatings">My Rating</a>
                    </li>
                    <li <%= request.getServletPath().contains("Profile") ? "class='active'" : ""%>>
                        <a href="<%= request.getContextPath()%>/Profile">Profile</a>
                    </li>
                    <li class="appointment-btn">
                        <a href="<%= request.getContextPath()%>/Login?action=logout">Logout</a>
                    </li>
                <% } else if (session.getAttribute("manager") != null) { %>
                    <!-- Manager Navigation -->
                    <li <%= request.getRequestURI().contains("manager_homepage.jsp") ? "class='active'" : ""%>>
                        <a href="<%= request.getContextPath()%>/ManagerHomepageServlet?action=dashboard">Dashboard</a>
                    </li>
                    <li <%= request.getServletPath().contains("ManagerServlet") ? "class='active'" : ""%>>
                        <a href="<%= request.getContextPath()%>/ManagerServlet?action=viewAll">Manage Staff</a>
                    </li>
                    <li <%= request.getServletPath().contains("view_appointments.jsp") ? "class='active'" : ""%>>
                        <a href="<%= request.getContextPath()%>/ManagerServlet?action=viewAppointments">View Appointments</a>
                    </li>
                    <li <%= request.getServletPath().contains("StaffRatingServlet") ? "class='active'" : ""%>>
                        <a href="<%= request.getContextPath()%>/StaffRatingServlet?action=viewAll">Ratings</a>
                    </li>
                    <li <%= request.getRequestURI().contains("reports.jsp") ? "class='active'" : ""%>>
                        <!-- // need to change here -->
                        <a href="<%= request.getContextPath()%>/ManagerServlet?action=viewReports">Reports</a>
                    </li>
                    <li <%= request.getServletPath().contains("Profile") ? "class='active'" : ""%>>
                        <a href="<%= request.getContextPath()%>/Profile">Profile</a>
                    </li>
                    <li class="appointment-btn">
                        <a href="<%= request.getContextPath()%>/Login?action=logout">Logout</a>
                    </li>
                <% } else { %>
                    <!-- Customer Navigation -->
                    <li <%= request.getServletPath().contains("CustomerHomepageServlet") ? "class='active'" : ""%>>
                        <a href="<%= request.getContextPath()%>/CustomerHomepageServlet">Home</a>
                    </li>
                    <li <%= request.getServletPath().contains("DoctorServlet") ? "class='active'" : ""%>>
                        <a href="<%= request.getContextPath()%>/DoctorServlet">Our Doctors</a>
                    </li>
                    <li <%= request.getRequestURI().contains("TreatmentServlet") && "viewAll".equals(request.getParameter("action")) ? "class='active'" : ""%>>
                        <a href="<%= request.getContextPath()%>/TreatmentServlet?action=viewAll">Treatment Types</a>
                    </li>
                    <li <%= pageName.equals("customer/appointment_history.jsp") ? "class='active'" : ""%>>
                        <a href="<%= request.getContextPath()%>/AppointmentServlet?action=history">Appointments</a>
                    </li>
                    <li <%= request.getServletPath().contains("Profile") ? "class='active'" : ""%>>
                        <a href="<%= request.getContextPath()%>/Profile">Profile</a>
                    </li>
                    <li <%= request.getRequestURI().contains("AppointmentServlet") ? "class='active'" : ""%>class="appointment-btn">
                        <a href="<%= request.getContextPath()%>/AppointmentServlet?action=book">Book an Appointment</a>
                    </li>
                <% } %>
            </ul>
        </div>

    </div>
</section>
