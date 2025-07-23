<%-- 
    Document   : manage_doc
    Created on : Jul 20, 2025, 6:11:32 PM
    Author     : chris
--%>

<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <title>JSP Page</title>
    </head>
    <body>
        <h2>Manager Panel</h2>
        <a href="register_doctor.jsp">Register New Doctor</a>
        <a href="${pageContext.request.contextPath}/DoctorServlet?action=list">List of Doctors</a>
    </body>
</html>