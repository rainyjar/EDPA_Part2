<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <title>Register Counter Staff</title>
        <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css" />
    </head>
    <body>
        <div class="box">
            <h2>Register Counter Staff</h2>

            <!-- Error Message -->
            <% if (request.getAttribute("error") != null) {%>
            <div class="msg"><%= request.getAttribute("error")%></div>
            <% }%>

            <form method="post" enctype="multipart/form-data" action="${pageContext.request.contextPath}/CounterStaffServlet">
                <label>Name:</label>
                <input type="text" name="name" value="${cstaff != null ? cstaff.name : ''}" required /><br>

                <label>Email:</label>
                <input type="email" name="email" value="${cstaff != null ? cstaff.email : ''}" required /><br>

                <label>Password:</label>
                <input type="password" name="password" value="${cstaff != null ? cstaff.password : ''}" required /><br>

                <label>Phone:</label>
                <input type="text" name="phone" value="${cstaff != null ? cstaff.phone : ''}" required /><br>

                <label>Gender:</label>
                <select name="gender" required>
                    <option value="" disabled ${cstaff == null ? "selected" : ""}>Choose Gender</option>
                    <option value="F" ${cstaff != null && cstaff.gender == 'F' ? "selected" : ""}>Female</option>
                    <option value="M" ${cstaff != null && cstaff.gender == 'M' ? "selected" : ""}>Male</option>
                </select><br>

                <label>Date of Birth:</label>
                <input type="date" name="dob" value="${cstaff != null ? cstaff.dob : ''}" required /><br>

                <!--// profile pic-->
                <label>Profile Picture: </label>
                <input type="file" name="profilePic" accept="image/*" required>

                <input class="login_btn" type="submit" value="Register" />
            </form>

        </form>
    </div>
</body>
</html>
