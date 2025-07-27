
import java.io.IOException;
import java.util.Date;
import javax.ejb.EJB;
import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import javax.servlet.http.Part;
import model.CounterStaff;
import model.CounterStaffFacade;
import model.Customer;
import model.CustomerFacade;
import model.Doctor;
import model.DoctorFacade;
import model.Manager;
import model.ManagerFacade;

@MultipartConfig
@WebServlet(urlPatterns = {"/Profile"})
public class Profile extends HttpServlet {

    @EJB
    private CounterStaffFacade counterStaffFacade;

    @EJB
    private CustomerFacade customerFacade;

    @EJB
    private DoctorFacade doctorFacade;

    @EJB
    private ManagerFacade managerFacade;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        UserInfo userInfo = getCurrentUser(session);

        if (userInfo == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        // Redirect to universal profile page
        response.sendRedirect(request.getContextPath() + "/profile.jsp");
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        UserInfo userInfo = getCurrentUser(session);

        if (userInfo == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        String action = request.getParameter("action");

        try {
            switch (action) {
                case "updateProfile":
                    handleUpdateProfile(request, response, userInfo);
                    break;
                case "changePassword":
                    handleChangePassword(request, response, userInfo);
                    break;
                case "updateProfilePic":
                    handleUpdateProfilePic(request, response, userInfo);
                    break;
                default:
                    response.sendRedirect(request.getContextPath() + "/profile.jsp?error=invalid_action");
            }
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + "/profile.jsp?error=system_error");
        }
    }

    // Helper class to hold user information
    private static class UserInfo {

        public Object user;
        public String userType;
        public String name;
        public String email;
        public String phone;
        public String gender;
        public Date dob;
        public String profilePic;
        public String password;

        public UserInfo(Object user, String userType) {
            this.user = user;
            this.userType = userType;

            // Extract common fields based on user type
            if (user instanceof Customer) {
                Customer c = (Customer) user;
                this.name = c.getName();
                this.email = c.getEmail();
                this.phone = c.getPhone();
                this.gender = c.getGender();
                this.dob = c.getDob();
                this.profilePic = c.getProfilePic();
                this.password = c.getPassword();
            } else if (user instanceof Doctor) {
                Doctor d = (Doctor) user;
                this.name = d.getName();
                this.email = d.getEmail();
                this.phone = d.getPhone();
                this.gender = d.getGender();
                this.dob = d.getDob();
                this.profilePic = d.getProfilePic();
                this.password = d.getPassword();
            } else if (user instanceof CounterStaff) {
                CounterStaff cs = (CounterStaff) user;
                this.name = cs.getName();
                this.email = cs.getEmail();
                this.phone = cs.getPhone();
                this.gender = cs.getGender();
                this.dob = cs.getDob();
                this.profilePic = cs.getProfilePic();
                this.password = cs.getPassword();
            } else if (user instanceof Manager) {
                Manager m = (Manager) user;
                this.name = m.getName();
                this.email = m.getEmail();
                this.phone = m.getPhone();
                this.gender = m.getGender();
                this.dob = m.getDob();
                this.profilePic = m.getProfilePic();
                this.password = m.getPassword();
            }
        }
    }

    // Get current user from session
    private UserInfo getCurrentUser(HttpSession session) {
        if (session == null) {
            return null;
        }

        Customer customer = (Customer) session.getAttribute("customer");
        if (customer != null) {
            return new UserInfo(customer, "customer");
        }

        Doctor doctor = (Doctor) session.getAttribute("doctor");
        if (doctor != null) {
            return new UserInfo(doctor, "doctor");
        }

        CounterStaff staff = (CounterStaff) session.getAttribute("staff");
        if (staff != null) {
            return new UserInfo(staff, "staff");
        }

        Manager manager = (Manager) session.getAttribute("manager");
        if (manager != null) {
            return new UserInfo(manager, "manager");
        }

        return null;
    }

    // Universal profile update handler
    private void handleUpdateProfile(HttpServletRequest request, HttpServletResponse response, UserInfo userInfo)
            throws ServletException, IOException {

        // Retrieve form fields
        String name = request.getParameter("name");
        String email = request.getParameter("email");
        String phone = request.getParameter("phone");
        String dobStr = request.getParameter("dob");
        String gender = request.getParameter("gender");

        // Validate required fields
        if (name == null || name.trim().isEmpty()
                || email == null || email.trim().isEmpty()
                || phone == null || phone.trim().isEmpty()
                || dobStr == null || dobStr.trim().isEmpty()
                || gender == null || gender.trim().isEmpty()) {

            response.sendRedirect(request.getContextPath() + "/profile.jsp?error=missing_fields");
            return;
        }

        // Validate email format
        if (!email.matches("^[a-zA-Z0-9_+&*-]+(?:\\.[a-zA-Z0-9_+&*-]+)*@(?:[a-zA-Z0-9-]+\\.)+[a-zA-Z]{2,7}$")) {
            response.sendRedirect(request.getContextPath() + "/profile.jsp?error=invalid_email");
            return;
        }

        // Check if email already exists (excluding current user)
        if (isEmailTaken(email, userInfo)) {
            response.sendRedirect(request.getContextPath() + "/profile.jsp?error=email_taken");
            return;
        }

        // Validate date is not in the future
        java.sql.Date dob = null;
        try {
            java.util.Date utilDate = new java.text.SimpleDateFormat("yyyy-MM-dd").parse(dobStr);
            dob = new java.sql.Date(utilDate.getTime());

            // Check if date is in the future
            if (dob.after(new java.sql.Date(System.currentTimeMillis()))) {
                response.sendRedirect(request.getContextPath() + "/profile.jsp?error=future_date");
                return;
            }
        } catch (Exception e) {
            response.sendRedirect(request.getContextPath() + "/profile.jsp?error=invalid_date");
            return;
        }

        // Update user object based on type
        updateUserFields(userInfo.user, userInfo.userType, name, email, phone, gender, dob);

        // Save to database and update session
        saveUserAndUpdateSession(request, userInfo);

        response.sendRedirect(request.getContextPath() + "/profile.jsp?success=profile_updated");
    }

    // Universal password change handler
    private void handleChangePassword(HttpServletRequest request, HttpServletResponse response, UserInfo userInfo)
            throws ServletException, IOException {

        String currentPassword = request.getParameter("currentPassword");
        String newPassword = request.getParameter("newPassword");
        String confirmPassword = request.getParameter("confirmPassword");

        // Validate required fields
        if (currentPassword == null || currentPassword.trim().isEmpty()
                || newPassword == null || newPassword.trim().isEmpty()
                || confirmPassword == null || confirmPassword.trim().isEmpty()) {

            response.sendRedirect(request.getContextPath() + "/profile.jsp?error=missing_fields");
            return;
        }

        // Verify current password
        if (!userInfo.password.equals(currentPassword)) {
            response.sendRedirect(request.getContextPath() + "/profile.jsp?error=invalid_password");
            return;
        }

        // Check if new passwords match
        if (!newPassword.equals(confirmPassword)) {
            response.sendRedirect(request.getContextPath() + "/profile.jsp?error=password_mismatch");
            return;
        }

        // Validate password length (minimum 6 characters)
        if (newPassword.length() < 6) {
            response.sendRedirect(request.getContextPath() + "/profile.jsp?error=weak_password");
            return;
        }

        // Update password
        updateUserPassword(userInfo.user, userInfo.userType, newPassword);

        // Save to database and update session
        saveUserAndUpdateSession(request, userInfo);

        response.sendRedirect(request.getContextPath() + "/profile.jsp?success=password_changed");
    }

    // Universal profile picture update handler
    private void handleUpdateProfilePic(HttpServletRequest request, HttpServletResponse response, UserInfo userInfo)
            throws ServletException, IOException {

        try {
            Part filePart = request.getPart("profilePic");
            if (filePart != null && filePart.getSize() > 0) {
                String fileName = null;
                try {
                    fileName = UploadImage.uploadProfilePicture(filePart, request.getServletContext());
                } catch (Exception e) {
                    e.printStackTrace();
                    response.sendRedirect(request.getContextPath() + "/profile.jsp?error=upload_failed");
                    return;
                }

                // Update profile picture
                updateUserProfilePic(userInfo.user, userInfo.userType, fileName);

                // Save to database and update session
                saveUserAndUpdateSession(request, userInfo);

                Thread.sleep(3000);
                response.sendRedirect(request.getContextPath() + "/profile.jsp?success=picture_updated");
            } else {
                response.sendRedirect(request.getContextPath() + "/profile.jsp?error=no_file");
            }
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + "/profile.jsp?error=upload_failed");
        }
    }

    // Helper methods
    private boolean isEmailTaken(String email, UserInfo userInfo) {
        // Check in all user types except current user
        Customer customer = customerFacade.searchEmail(email);
        if (customer != null && !(userInfo.userType.equals("customer") && customer.getId() == ((Customer) userInfo.user).getId())) {
            return true;
        }

        Doctor doctor = doctorFacade.searchEmail(email);
        if (doctor != null && !(userInfo.userType.equals("doctor") && doctor.getId() == ((Doctor) userInfo.user).getId())) {
            return true;
        }

        CounterStaff staff = counterStaffFacade.searchEmail(email);
        if (staff != null && !(userInfo.userType.equals("staff") && staff.getId() == ((CounterStaff) userInfo.user).getId())) {
            return true;
        }

        Manager manager = managerFacade.searchEmail(email);
        if (manager != null && !(userInfo.userType.equals("manager") && manager.getId() == ((Manager) userInfo.user).getId())) {
            return true;
        }

        return false;
    }

    private void updateUserFields(Object user, String userType, String name, String email, String phone, String gender, java.sql.Date dob) {
        switch (userType) {
            case "customer":
                Customer customer = (Customer) user;
                customer.setName(name);
                customer.setEmail(email);
                customer.setPhone(phone);
                customer.setGender(gender);
                customer.setDob(dob);
                break;
            case "doctor":
                Doctor doctor = (Doctor) user;
                doctor.setName(name);
                doctor.setEmail(email);
                doctor.setPhone(phone);
                doctor.setGender(gender);
                doctor.setDob(dob);
                break;
            case "staff":
                CounterStaff staff = (CounterStaff) user;
                staff.setName(name);
                staff.setEmail(email);
                staff.setPhone(phone);
                staff.setGender(gender);
                staff.setDob(dob);
                break;
            case "manager":
                Manager manager = (Manager) user;
                manager.setName(name);
                manager.setEmail(email);
                manager.setPhone(phone);
                manager.setGender(gender);
                manager.setDob(dob);
                break;
        }
    }

    private void updateUserPassword(Object user, String userType, String password) {
        switch (userType) {
            case "customer":
                ((Customer) user).setPassword(password);
                break;
            case "doctor":
                ((Doctor) user).setPassword(password);
                break;
            case "staff":
                ((CounterStaff) user).setPassword(password);
                break;
            case "manager":
                ((Manager) user).setPassword(password);
                break;
        }
    }

    private void updateUserProfilePic(Object user, String userType, String profilePic) {
        switch (userType) {
            case "customer":
                ((Customer) user).setProfilePic(profilePic);
                break;
            case "doctor":
                ((Doctor) user).setProfilePic(profilePic);
                break;
            case "staff":
                ((CounterStaff) user).setProfilePic(profilePic);
                break;
            case "manager":
                ((Manager) user).setProfilePic(profilePic);
                break;
        }
    }

    private void saveUserAndUpdateSession(HttpServletRequest request, UserInfo userInfo) {
        HttpSession session = request.getSession();

        switch (userInfo.userType) {
            case "customer":
                customerFacade.edit((Customer) userInfo.user);
                session.setAttribute("customer", userInfo.user);
                break;
            case "doctor":
                doctorFacade.edit((Doctor) userInfo.user);
                session.setAttribute("doctor", userInfo.user);
                break;
            case "staff":
                counterStaffFacade.edit((CounterStaff) userInfo.user);
                session.setAttribute("staff", userInfo.user);
                break;
            case "manager":
                managerFacade.edit((Manager) userInfo.user);
                session.setAttribute("manager", userInfo.user);
                break;
        }
    }
}
