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
                <li <%= request.getServletPath().contains("CustomerHomepageServlet") ? "class='active'" : ""%>>
                    <a href="<%= request.getContextPath()%>/CustomerHomepageServlet">Home</a>
                </li>

                <li <%= pageName.equals("customer/team.jsp") ? "class='active'" : ""%>>
                    <a href="<%= request.getContextPath()%>/customer/team.jsp">Our Doctors</a>
                </li>
                <li <%= request.getRequestURI().contains("TreatmentServlet") && "viewAll".equals(request.getParameter("action")) ? "class='active'" : ""%>>
                    <a href="<%= request.getContextPath()%>/TreatmentServlet?action=viewAll">Treatment Types</a>
                </li>
                <li <%= pageName.equals("customer/appointment_history.jsp") ? "class='active'" : ""%>>
                    <a href="<%= request.getContextPath()%>/customer/appointment_history.jsp">Appointments</a>
                </li>
                <li <%= pageName.equals("customer/cust_profile.jsp") ? "class='active'" : ""%>>
                    <a href="<%= request.getContextPath()%>/customer/cust_profile.jsp" class="smoothScroll">Profile</a>
                </li>
                <li <%= request.getRequestURI().contains("AppointmentServlet") ? "class='active'" : ""%>class="appointment-btn">
                    <a href="<%= request.getContextPath()%>/AppointmentServlet?action=book">Book an Appointment</a>
                </li>

            </ul>
        </div>

    </div>
</section>
