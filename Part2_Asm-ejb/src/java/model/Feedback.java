/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package model;

import java.io.Serializable;
import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.*;

/**
 *
 * @author chris
 */
@Entity
public class Feedback implements Serializable {

    private static final long serialVersionUID = 1L;
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private int id;

    @ManyToOne
    @JoinColumn(name = "appointment_id")
    private Appointment appointment;

    @ManyToOne
    @JoinColumn(name = "from_customer_id")
    private Customer fromCustomer;

    @ManyToOne(optional = true)
    @JoinColumn(name = "to_doc_id")
    private Doctor toDoctor;

    @ManyToOne(optional = true)
    @JoinColumn(name = "to_staff_id")
    private CounterStaff toStaff;

    private String custComment;
    private int rating;

    public Feedback() {
    }

    public Feedback(Appointment appointment, Customer fromCustomer, Doctor toDoctor, CounterStaff toStaff, String custComment, int rating) {
        this.appointment = appointment;
        this.fromCustomer = fromCustomer;
        this.toDoctor = toDoctor;
        this.toStaff = toStaff;
        this.custComment = custComment;
        this.rating = rating;
    }
    
    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public Appointment getAppointment() {
        return appointment;
    }

    public void setAppointment(Appointment appointment) {
        this.appointment = appointment;
    }

    public Customer getFromCustomer() {
        return fromCustomer;
    }

    public void setFromCustomer(Customer fromCustomer) {
        this.fromCustomer = fromCustomer;
    }

    public Doctor getToDoctor() {
        return toDoctor;
    }

    public void setToDoctor(Doctor toDoctor) {
        this.toDoctor = toDoctor;
    }

    public CounterStaff getToStaff() {
        return toStaff;
    }

    public void setToStaff(CounterStaff toStaff) {
        this.toStaff = toStaff;
    }

    public String getCustComment() {
        return custComment;
    }

    public void setCustComment(String custComment) {
        this.custComment = custComment;
    }

    public int getRating() {
        return rating;
    }

    public void setRating(int rating) {
        this.rating = rating;
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
        Feedback other = (Feedback) object;
        if (this.id != other.id) {
            return false;
        }
        return true;
    }
    
    @Override
    public String toString() {
        return "model.Feedback[ id=" + id + " ]";
    }

}
