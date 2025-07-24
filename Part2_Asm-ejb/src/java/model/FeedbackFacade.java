/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package model;

import java.util.List;
import javax.ejb.Stateless;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;
import javax.persistence.Query;

/**
 * Enhanced FeedbackFacade with custom methods for feedback operations
 * @author chris
 */
@Stateless
public class FeedbackFacade extends AbstractFacade<Feedback> {

    @PersistenceContext(unitName = "Part2_Asm-ejbPU")
    private EntityManager em;

    @Override
    protected EntityManager getEntityManager() {
        return em;
    }

    public FeedbackFacade() {
        super(Feedback.class);
    }
    
    /**
     * Check if feedback exists for a specific appointment
     * @param appointmentId The appointment ID to check
     * @return true if feedback exists, false otherwise
     */
    public boolean feedbackExistsForAppointment(int appointmentId) {
        try {
            Query query = em.createQuery("SELECT COUNT(f) FROM Feedback f WHERE f.appointment.id = :appointmentId");
            query.setParameter("appointmentId", appointmentId);
            Long count = (Long) query.getSingleResult();
            return count > 0;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }
    
    /**
     * Get all feedback for a specific appointment
     * @param appointmentId The appointment ID
     * @return List of feedback for the appointment
     */
    public List<Feedback> findByAppointmentId(int appointmentId) {
        try {
            Query query = em.createQuery("SELECT f FROM Feedback f WHERE f.appointment.id = :appointmentId");
            query.setParameter("appointmentId", appointmentId);
            return query.getResultList();
        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }
    }
    
    /**
     * Get all feedback for a specific doctor
     * @param doctorId The doctor ID
     * @return List of feedback for the doctor
     */
    public List<Feedback> findByDoctorId(int doctorId) {
        try {
            Query query = em.createQuery("SELECT f FROM Feedback f WHERE f.toDoctor.id = :doctorId ORDER BY f.id DESC");
            query.setParameter("doctorId", doctorId);
            return query.getResultList();
        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }
    }
    
    /**
     * Get all feedback for a specific counter staff
     * @param staffId The counter staff ID
     * @return List of feedback for the counter staff
     */
    public List<Feedback> findByCounterStaffId(int staffId) {
        try {
            Query query = em.createQuery("SELECT f FROM Feedback f WHERE f.toStaff.id = :staffId ORDER BY f.id DESC");
            query.setParameter("staffId", staffId);
            return query.getResultList();
        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }
    }
    
    /**
     * Get average rating for a specific doctor
     * @param doctorId The doctor ID
     * @return Average rating or 0.0 if no feedback exists
     */
    public double getAverageRatingForDoctor(int doctorId) {
        try {
            Query query = em.createQuery("SELECT AVG(f.rating) FROM Feedback f WHERE f.toDoctor.id = :doctorId");
            query.setParameter("doctorId", doctorId);
            Double result = (Double) query.getSingleResult();
            return result != null ? result : 0.0;
        } catch (Exception e) {
            e.printStackTrace();
            return 0.0;
        }
    }
    
    /**
     * Get average rating for a specific counter staff
     * @param staffId The counter staff ID
     * @return Average rating or 0.0 if no feedback exists
     */
    public double getAverageRatingForCounterStaff(int staffId) {
        try {
            Query query = em.createQuery("SELECT AVG(f.rating) FROM Feedback f WHERE f.toStaff.id = :staffId");
            query.setParameter("staffId", staffId);
            Double result = (Double) query.getSingleResult();
            return result != null ? result : 0.0;
        } catch (Exception e) {
            e.printStackTrace();
            return 0.0;
        }
    }
    
    /**
     * Get feedback count for a specific doctor
     * @param doctorId The doctor ID
     * @return Number of feedback entries for the doctor
     */
    public long getFeedbackCountForDoctor(int doctorId) {
        try {
            Query query = em.createQuery("SELECT COUNT(f) FROM Feedback f WHERE f.toDoctor.id = :doctorId");
            query.setParameter("doctorId", doctorId);
            return (Long) query.getSingleResult();
        } catch (Exception e) {
            e.printStackTrace();
            return 0;
        }
    }
    
    /**
     * Get feedback count for a specific counter staff
     * @param staffId The counter staff ID
     * @return Number of feedback entries for the counter staff
     */
    public long getFeedbackCountForCounterStaff(int staffId) {
        try {
            Query query = em.createQuery("SELECT COUNT(f) FROM Feedback f WHERE f.toStaff.id = :staffId");
            query.setParameter("staffId", staffId);
            return (Long) query.getSingleResult();
        } catch (Exception e) {
            e.printStackTrace();
            return 0;
        }
    }
}
