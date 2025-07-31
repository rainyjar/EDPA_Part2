/*
 * LeaveRequestFacade - EJB Facade for LeaveRequest entity
 * Handles doctor unavailability data operations
 */
package model;

import java.sql.Time;
import java.util.Date;
import java.util.List;
import javax.ejb.Stateless;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;
import javax.persistence.Query;
import javax.persistence.TypedQuery;

/**
 * EJB Facade for LeaveRequest entity operations
 * @author leeja
 */
@Stateless
public class LeaveRequestFacade extends AbstractFacade<LeaveRequest> {

    @PersistenceContext(unitName = "Part2_Asm-ejbPU")
    private EntityManager em;

    @Override
    protected EntityManager getEntityManager() {
        return em;
    }

    public LeaveRequestFacade() {
        super(LeaveRequest.class);
    }

    /**
     * Find all unavailabilities for a specific doctor
     */
    public List<LeaveRequest> findByDoctor(int doctorId) {
        try {
            TypedQuery<LeaveRequest> query = em.createQuery("SELECT s FROM ScheduleUnavailable s WHERE s.doctor.id = :doctorId ORDER BY s.unavailableDate, s.startTime", 
                LeaveRequest.class);
            query.setParameter("doctorId", doctorId);
            return query.getResultList();
        } catch (Exception e) {
            System.out.println("Error finding unavailabilities for doctor " + doctorId + ": " + e.getMessage());
            return new java.util.ArrayList<>();
        }
    }

    /**
     * Find unavailabilities for a specific doctor on a specific date
     */
    public List<LeaveRequest> findByDoctorAndDate(int doctorId, Date unavailableDate) {
        try {
            TypedQuery<LeaveRequest> query = em.createQuery("SELECT s FROM ScheduleUnavailable s WHERE s.doctor.id = :doctorId AND s.unavailableDate = :unavailableDate ORDER BY s.startTime", 
                LeaveRequest.class);
            query.setParameter("doctorId", doctorId);
            query.setParameter("unavailableDate", unavailableDate);
            return query.getResultList();
        } catch (Exception e) {
            System.out.println("Error finding unavailabilities for doctor " + doctorId + " on date " + unavailableDate + ": " + e.getMessage());
            return new java.util.ArrayList<>();
        }
    }

    /**
     * Check if a doctor is unavailable at a specific date and time
     */
    public boolean isDoctorUnavailable(int doctorId, Date appointmentDate, Time appointmentTime) {
        try {
            TypedQuery<Long> query = em.createQuery(
                "SELECT COUNT(s) FROM ScheduleUnavailable s WHERE s.doctor.id = :doctorId " +
                "AND s.unavailableDate = :appointmentDate " +
                "AND s.startTime <= :appointmentTime AND s.endTime > :appointmentTime", 
                Long.class);
            query.setParameter("doctorId", doctorId);
            query.setParameter("appointmentDate", appointmentDate);
            query.setParameter("appointmentTime", appointmentTime);
            
            Long count = query.getSingleResult();
            return count != null && count > 0;
        } catch (Exception e) {
            System.out.println("Error checking doctor unavailability: " + e.getMessage());
            return false; // If query fails, assume doctor is available to be safe
        }
    }

    /**
     * Find future unavailabilities for a doctor (for rescheduling affected appointments)
     */
    public List<LeaveRequest> findFutureUnavailabilities(int doctorId) {
        try {
            Date today = new Date();
            TypedQuery<LeaveRequest> query = em.createQuery("SELECT s FROM ScheduleUnavailable s WHERE s.doctor.id = :doctorId AND s.unavailableDate >= :today ORDER BY s.unavailableDate, s.startTime", 
                LeaveRequest.class);
            query.setParameter("doctorId", doctorId);
            query.setParameter("today", today);
            return query.getResultList();
        } catch (Exception e) {
            System.out.println("Error finding future unavailabilities for doctor " + doctorId + ": " + e.getMessage());
            return new java.util.ArrayList<>();
        }
    }

    /**
     * Find overlapping unavailabilities for validation
     */
    public List<LeaveRequest> findOverlappingUnavailabilities(int doctorId, Date unavailableDate, Time startTime, Time endTime) {
        try {
            TypedQuery<LeaveRequest> query = em.createQuery("SELECT s FROM ScheduleUnavailable s WHERE s.doctor.id = :doctorId " +
                "AND s.unavailableDate = :unavailableDate " +
                "AND ((s.startTime <= :startTime AND s.endTime > :startTime) " +
                "OR (s.startTime < :endTime AND s.endTime >= :endTime) " +
                "OR (s.startTime >= :startTime AND s.endTime <= :endTime))", 
                LeaveRequest.class);
            query.setParameter("doctorId", doctorId);
            query.setParameter("unavailableDate", unavailableDate);
            query.setParameter("startTime", startTime);
            query.setParameter("endTime", endTime);
            return query.getResultList();
        } catch (Exception e) {
            System.out.println("Error finding overlapping unavailabilities: " + e.getMessage());
            return new java.util.ArrayList<>();
        }
    }

    /**
     * Delete past unavailabilities (cleanup method)
     */
    public int deletePastUnavailabilities() {
        try {
            Date today = new Date();
            Query query = em.createQuery(
                "DELETE FROM ScheduleUnavailable s WHERE s.unavailableDate < :today");
            query.setParameter("today", today);
            return query.executeUpdate();
        } catch (Exception e) {
            System.out.println("Error deleting past unavailabilities: " + e.getMessage());
            return 0;
        }
    }
}
