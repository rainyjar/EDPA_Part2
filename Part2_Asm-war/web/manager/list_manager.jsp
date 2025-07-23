<%@ page import="java.util.List" %>
<%@ page import="model.Manager" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>


<html>
<head>
    <title>Manager List</title>
    <link rel="stylesheet" type="text/css" href="${pageContext.request.contextPath}/css/style.css">
</head>
<body>
<h2>Manager List</h2>

<table border="1">
    <tr>
        <th>Name</th>
        <th>Email</th>
        <th>Phone</th>
        <th>Gender</th>
        <th>DOB</th>
        <th>Profile Picture</th>
        <th>Actions</th>
    </tr>
    <c:forEach var="manager" items="${managerList}">
        <tr>
            <td>${manager.name}</td>
            <td>${manager.email}</td>
            <td>${manager.phone}</td>
            <td>${manager.gender}</td>
            <td><fmt:formatDate value="${manager.dob}" pattern="yyyy-MM-dd" /></td>
            <td>${manager.profilePic}</td>

            <td>
                <form method="get" action="${pageContext.request.contextPath}/ManagerServlet" style="display:inline;">
                    <input type="hidden" name="action" value="edit" />
                    <input type="hidden" name="id" value="${manager.id}" />
                    <input type="submit" value="Edit" />
                </form>

                <form method="post" action="${pageContext.request.contextPath}/ManagerServlet" style="display:inline;" 
                      onsubmit="return confirm('Are you sure you want to delete this manager?');">
                    <input type="hidden" name="action" value="delete" />
                    <input type="hidden" name="id" value="${manager.id}" />
                    <input type="submit" value="Delete" />
                </form>
            </td>
        </tr>
    </c:forEach>
</table>
       
</body>
</html>
