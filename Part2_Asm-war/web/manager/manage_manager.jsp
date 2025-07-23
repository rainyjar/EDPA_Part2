<%-- 
    Document   : manage_manager
    Created on : Jul 20, 2025, 6:10:31 PM
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
        <a href="register_manager.jsp">Register New Manager</a>
        <a href="${pageContext.request.contextPath}/ManagerServlet?action=list">List of Managers</a>

    </body>
</html>
