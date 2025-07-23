<%-- 
    Document   : manage_cs
    Created on : Jul 20, 2025, 6:10:56 PM
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
        <h1>Hello World!</h1>
        <h2>Manager Panel</h2>
        <a href="register_cs.jsp">Register New Counter Staff</a>
        <a href="${pageContext.request.contextPath}/CounterStaffServlet?action=list">List of Counter Staff</a>

    </body>
</html>
