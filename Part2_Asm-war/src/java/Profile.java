
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
        public String ic;
        public String address;

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
                this.ic = c.getIc();
                this.address = c.getAddress();
            } else if (user instanceof Doctor) {
                Doctor d = (Doctor) user;
                this.name = d.getName();
                this.email = d.getEmail();
                this.phone = d.getPhone();
                this.gender = d.getGender();
                this.dob = d.getDob();
                this.profilePic = d.getProfilePic();
                this.password = d.getPassword();
                this.ic = d.getIc();
                this.address = d.getAddress();
            } else if (user instanceof CounterStaff) {
                CounterStaff cs = (CounterStaff) user;
                this.name = cs.getName();
                this.email = cs.getEmail();
                this.phone = cs.getPhone();
                this.gender = cs.getGender();
                this.dob = cs.getDob();
                this.profilePic = cs.getProfilePic();
                this.password = cs.getPassword();
                this.ic = cs.getIc();
                this.address = cs.getAddress();
            } else if (user instanceof Manager) {
                Manager m = (Manager) user;
                this.name = m.getName();
                this.email = m.getEmail();
                this.phone = m.getPhone();
                this.gender = m.getGender();
                this.dob = m.getDob();
                this.profilePic = m.getProfilePic();
                this.password = m.getPassword();
                this.ic = m.getIc();
                this.address = m.getAddress();
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
        String ic = request.getParameter("nric");
        String address = request.getParameter("address");

        // Validate essential fields only (name and email)
        if (name == null || name.trim().isEmpty()
                || email == null || email.trim().isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/profile.jsp?error=missing_essential_fields");
            return;
        }

        // Validate email format
        if (!email.matches("^[a-zA-Z0-9_+&*-]+(?:\\.[a-zA-Z0-9_+&*-]+)*@(?:[a-zA-Z0-9-]+\\.)+[a-zA-Z]{2,7}$")) {
            response.sendRedirect(request.getContextPath() + "/profile.jsp?error=invalid_email");
            return;
        }

        // validate phone only if provided
        if (phone != null && !phone.trim().isEmpty()) {
            String phoneRegex = "^[\\+]?[-() 0-9]{9,12}$";
            if (!phone.matches(phoneRegex)) {
                response.sendRedirect(request.getContextPath() + "/profile.jsp?error=invalid_phone");
                return;
            }
        }

        // validate address only if provided
        if (address != null && !address.trim().isEmpty()) {
            // Allow more characters in address and simplify regex
            String addressRegex = "^[A-Za-z0-9\\s,./#\\-']{3,255}$";
            if (!address.matches(addressRegex)) {
                response.sendRedirect(request.getContextPath() + "/profile.jsp?error=invalid_address");
                return;
            }
        }

        // validate ic only if provided
        if (ic != null && !ic.trim().isEmpty()) {
            String icRegex = "^\\d{6}-\\d{2}-\\d{4}$";
            if (!ic.matches(icRegex)) {
                response.sendRedirect(request.getContextPath() + "/profile.jsp?error=invalid_ic");
                return;
            }

            // Check if the current user already has this IC value - if so, it's a no-op update
            boolean isCurrentUserIc = false;

            if (userInfo.userType.equals("customer")) {
                Customer customer = (Customer) userInfo.user;
                if (ic.equals(customer.getIc())) {
                    isCurrentUserIc = true;
                }
            } else if (userInfo.userType.equals("doctor")) {
                Doctor doctor = (Doctor) userInfo.user;
                if (ic.equals(doctor.getIc())) {
                    isCurrentUserIc = true;
                }
            } else if (userInfo.userType.equals("staff")) {
                CounterStaff staff = (CounterStaff) userInfo.user;
                if (ic.equals(staff.getIc())) {
                    isCurrentUserIc = true;
                }
            } else if (userInfo.userType.equals("manager")) {
                Manager manager = (Manager) userInfo.user;
                if (ic.equals(manager.getIc())) {
                    isCurrentUserIc = true;
                }
            }

            // Only do uniqueness check if this is not the current user's IC
            if (!isCurrentUserIc) {
                // Skip the uniqueness check for now - this is handled by the database
                // If it fails, our try-catch will catch the exception
            }
        }

        // Check if email already exists (excluding current user)
        if (isEmailTaken(email, userInfo)) {
            response.sendRedirect(request.getContextPath() + "/profile.jsp?error=email_taken");
            return;
        }

        // Process date of birth only if provided
        java.sql.Date dob = null;
        if (dobStr != null && !dobStr.trim().isEmpty()) {
            try {
                java.util.Date utilDate = new java.text.SimpleDateFormat("yyyy-MM-dd").parse(dobStr);
                dob = new java.sql.Date(utilDate.getTime());

                // Check if date is in the future
                if (dob.after(new java.sql.Date(System.currentTimeMillis()))) {
                    response.sendRedirect(request.getContextPath() + "/profile.jsp?error=future_date");
                    return;
                }
            } catch (Exception e) {
                e.printStackTrace(); // Log the error for debugging
                response.sendRedirect(request.getContextPath() + "/profile.jsp?error=invalid_date");
                return;
            }
        }

        try {
            // Update user object based on type
            updateUserFields(userInfo.user, userInfo.userType, name, email, phone, gender, dob, ic, address);

            // Save to database and update session
            saveUserAndUpdateSession(request, userInfo);

            response.sendRedirect(request.getContextPath() + "/profile.jsp?success=profile_updated");
        } catch (Exception e) {
            // Log the error
            e.printStackTrace();

            // Check if this is a uniqueness constraint violation (likely IC/NRIC constraint)
            String errorMsg = e.getMessage() != null ? e.getMessage().toLowerCase() : "";

            if (errorMsg.contains("constraint") || errorMsg.contains("unique")
                    || errorMsg.contains("duplicate") || errorMsg.contains("violat")
                    || errorMsg.contains("ic") || errorMsg.contains("nric")) {
                // NRIC/IC already in use
                response.sendRedirect(request.getContextPath() + "/profile.jsp?error=ic_taken");
            } else if (ic != null && !ic.trim().isEmpty()) {
                // If we were trying to update NRIC and got a different error
                response.sendRedirect(request.getContextPath() + "/profile.jsp?error=nric_update_failed");
            } else {
                // Generic system error
                response.sendRedirect(request.getContextPath() + "/profile.jsp?error=system_error");
            }
        }
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
                    fileName = UploadImage.uploadImage(filePart, "profile_pictures");
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
        // Skip check if user is updating with their own current email
        if (email.equals(userInfo.email)) {
            return false; // User is keeping their same email - not taken
        }

        // Check if email exists in any user type
        Customer customer = customerFacade.searchEmail(email);

        if (customer != null) {
            return true; // Email taken by a customer
        }

        Doctor doctor = doctorFacade.searchEmail(email);
        if (doctor != null) {
            return true; // Email taken by a doctor
        }

        CounterStaff staff = counterStaffFacade.searchEmail(email);
        if (staff != null) {
            return true; // Email taken by counter staff
        }

        Manager manager = managerFacade.searchEmail(email);
        if (manager != null) {
            return true; // Email taken by a manager
        }

        return false; // Email is available
    }

    private void updateUserFields(Object user, String userType, String name, String email, String phone, String gender, java.sql.Date dob, String ic, String address) {
        switch (userType) {
            case "customer":
                Customer customer = (Customer) user;
                customer.setName(name);
                customer.setEmail(email);
                customer.setPhone(phone != null && !phone.trim().isEmpty() ? phone : customer.getPhone());
                customer.setGender(gender != null && !gender.trim().isEmpty() ? gender : customer.getGender());
                customer.setDob(dob != null ? dob : customer.getDob());
                customer.setIc(ic != null && !ic.trim().isEmpty() ? ic : customer.getIc());
                customer.setAddress(address != null && !address.trim().isEmpty() ? address : customer.getAddress());
                break;
            case "doctor":
                Doctor doctor = (Doctor) user;
                doctor.setName(name);
                doctor.setEmail(email);
                doctor.setPhone(phone != null && !phone.trim().isEmpty() ? phone : doctor.getPhone());
                doctor.setGender(gender != null && !gender.trim().isEmpty() ? gender : doctor.getGender());
                doctor.setDob(dob != null ? dob : doctor.getDob());
                doctor.setIc(ic != null && !ic.trim().isEmpty() ? ic : doctor.getIc());
                doctor.setAddress(address != null && !address.trim().isEmpty() ? address : doctor.getAddress());
                break;
            case "staff":
                CounterStaff staff = (CounterStaff) user;
                staff.setName(name);
                staff.setEmail(email);
                staff.setPhone(phone != null && !phone.trim().isEmpty() ? phone : staff.getPhone());
                staff.setGender(gender != null && !gender.trim().isEmpty() ? gender : staff.getGender());
                staff.setDob(dob != null ? dob : staff.getDob());
                staff.setIc(ic != null && !ic.trim().isEmpty() ? ic : staff.getIc());
                staff.setAddress(address != null && !address.trim().isEmpty() ? address : staff.getAddress());
                break;
            case "manager":
                Manager manager = (Manager) user;
                manager.setName(name);
                manager.setEmail(email);
                manager.setPhone(phone != null && !phone.trim().isEmpty() ? phone : manager.getPhone());
                manager.setGender(gender != null && !gender.trim().isEmpty() ? gender : manager.getGender());
                manager.setDob(dob != null ? dob : manager.getDob());
                manager.setIc(ic != null && !ic.trim().isEmpty() ? ic : manager.getIc());
                manager.setAddress(address != null && !address.trim().isEmpty() ? address : manager.getAddress());
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
