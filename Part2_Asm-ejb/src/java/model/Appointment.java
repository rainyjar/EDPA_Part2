/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package model;

import java.io.Serializable;
import java.sql.Time;
import java.util.Date;
import java.util.List;
import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.*;

/**
 *
 * @author chris
 */
@Entity
public class Appointment implements Serializable {

    private static final long serialVersionUID = 1L;
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private int id;

    private Date appointmentDate;
    private Time appointmentTime;
    private String status;

    @Lob
    @Column(length = 32700)
    private String custMessage;
    @Lob
    @Column(length = 32700)
    private String docMessage;

    @Lob
    @Column(length = 32700)
    private String staffMessage;
    
    @ManyToOne
    @JoinColumn(name = "customer_id")
    private Customer customer;

    @ManyToOne
    @JoinColumn(name = "doc_id")
    private Doctor doctor;

    @ManyToOne
    @JoinColumn(name = "treatment_id")
    private Treatment treatment;

    @ManyToOne
    @JoinColumn(name = "counter_staff_id")
    private CounterStaff counterStaff;

    @OneToMany(mappedBy = "appointment")
    private List<Feedback> feedbacks;

    @OneToOne(mappedBy = "appointment")
    private Receipt receipt;

//    constructors
    public Appointment() {
    }

    public Appointment(Date appointmentDate, Time appointmentTime, String custMessage, String docMessage, String staffMessage, String status, Customer customer, Doctor doctor, Treatment treatment, CounterStaff counterStaff, List<Feedback> feedbacks, Receipt receipt) {
        this.appointmentDate = appointmentDate;
        this.appointmentTime = appointmentTime;
        this.custMessage = custMessage;
        this.docMessage = docMessage;
        this.staffMessage = staffMessage;
        this.status = status;
        this.customer = customer;
        this.doctor = doctor;
        this.treatment = treatment;
        this.counterStaff = counterStaff;
        this.feedbacks = feedbacks;
        this.receipt = receipt;
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public Date getAppointmentDate() {
        return appointmentDate;
    }

    public void setAppointmentDate(Date appointmentDate) {
        this.appointmentDate = appointmentDate;
    }

    public Time getAppointmentTime() {
        return appointmentTime;
    }

    public void setAppointmentTime(Time appointmentTime) {
        this.appointmentTime = appointmentTime;
    }

    public String getCustMessage() {
        return custMessage;
    }

    public void setCustMessage(String custMessage) {
        this.custMessage = custMessage;
    }

    public String getDocMessage() {
        return docMessage;
    }

    public void setDocMessage(String docMessage) {
        this.docMessage = docMessage;
    }

    public String getStaffMessage() {
        return staffMessage;
    }

    public void setStaffMessage(String staffMessage) {
        this.staffMessage = staffMessage;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public Customer getCustomer() {
        return customer;
    }

    public void setCustomer(Customer customer) {
        this.customer = customer;
    }

    public Doctor getDoctor() {
        return doctor;
    }

    public void setDoctor(Doctor doctor) {
        this.doctor = doctor;
    }

    public Treatment getTreatment() {
        return treatment;
    }

    public void setTreatment(Treatment treatment) {
        this.treatment = treatment;
    }

    public CounterStaff getCounterStaff() {
        return counterStaff;
    }

    public void setCounterStaff(CounterStaff counterStaff) {
        this.counterStaff = counterStaff;
    }

    public List<Feedback> getFeedbacks() {
        return feedbacks;
    }

    public void setFeedbacks(List<Feedback> feedbacks) {
        this.feedbacks = feedbacks;
    }

    public Receipt getReceipt() {
        return receipt;
    }

    public void setReceipt(Receipt receipt) {
        this.receipt = receipt;
    }

    @Override
    public int hashCode() {
        int hash = 0;
        hash += (int) id;
        return hash;
    }

    @Override
    public boolean equals(Object object) {
        // TODO: Warning - this method won't work in the case the id fields are not set
        if (!(object instanceof Receipt)) {
            return false;
        }
        Appointment other = (Appointment) object;
        if (this.id != other.id) {
            return false;
        }
        return true;
    }

    @Override
    public String toString() {
        return "model.Appointment[ id=" + id + " ]";
    }

}
