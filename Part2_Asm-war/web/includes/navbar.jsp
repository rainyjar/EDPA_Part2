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
               <a href="<%= request.getContextPath() %>/customer/cust_homepage.jsp" class="img-responsive">
                    <img src="<%= request.getContextPath() %>/images/amc_logo.png" alt="APU Medical Center Logo">
               </a>
          </div>

           <!--MENU LINKS--> 
          <div class="collapse navbar-collapse">
               <ul class="nav navbar-nav navbar-right">
                    <li <%= pageName.equals("customer/cust_homepage.jsp") ? "class='active'" : "" %>><a href="<%= request.getContextPath() %>/customer/cust_homepage.jsp">Home</a></li>
                    <li><a href="#about" class="smoothScroll">About Us</a></li>
                    <li <%= pageName.equals("customer/team.jsp") ? "class='active'" : "" %>><a href="<%= request.getContextPath() %>/customer/team.jsp">Our Doctors</a></li>
                    <li <%= pageName.equals("customer/treatment.jsp") ? "class='active'" : "" %>><a href="<%= request.getContextPath() %>/customer/treatment.jsp">Treatment Types</a></li>
                    <li><a href="<%= request.getContextPath() %>/customer/cust_homepage.jsp#profile" class="smoothScroll">Profile</a></li>
                    <li class="appointment-btn"><a href="<%= request.getContextPath() %>/customer/appointment.jsp">Make an appointment</a></li>
               </ul>
          </div>
     </div>
</section>
