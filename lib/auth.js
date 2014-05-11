/**
 * Manager: mani
 * Date: 14-3-6
 * Time: PM3:23
 */
var Manager = require('../models').Manager,
    RememberMeStrategy = require('passport-remember-me'),
    LocalStrategy = require('passport-local').Strategy;

exports.config = function (settings) {

};

/**
 * A helper method to retrieve a user from a local DB and ensure that the provided password matches.
 * @param req
 * @param res
 * @param next
 */
exports.localStrategy = function () {

    return new LocalStrategy(function (username, password, done) {

        console.warn('Use LocalStrategy '+username);

        //Retrieve the user from the database by login
        Manager.getAuthenticated(username, password, function(err, user, reason){
            console.warn('Auth Result ', err, user, reason);
            if(!user){
                return done(err, false, {message:reason});
            }
            done(null, user);
        })
    });
};

exports.rememberme = function(){

//    return new RememberMeStrategy(function(token, done) {
//            consumeRememberMeToken(token, function(err, uid) {
//                if (err) { return done(err); }
//                if (!uid) { return done(null, false); }
//
//                findById(uid, function(err, user) {
//                    if (err) { return done(err); }
//                    if (!user) { return done(null, false); }
//                    return done(null, user);
//                });
//            });
//        }
//    ));

}


//
//function issueToken(user, done) {
//    var token = utils.randomString(64);
//    saveRememberMeToken(token, user.id, function(err) {
//        if (err) { return done(err); }
//        return done(null, token);
//    });
//}

/**
 * A helper method to determine if a user has been authenticated, and if they have the right role.
 * If the user is not known, redirect to the login page. If the role doesn't match, show a 403 page.
 * @param role The role that a user should have to pass authentication.
 */
exports.isAuthenticated = function (role) {

    return function (req, res, next) {

        if (!req.isAuthenticated()) {
            //If the user is not authorized, save the location that was being accessed so we can redirect afterwards.
            req.session.goingTo = req.url;
            res.redirect('/');
            return;
        }

        //If a role was specified, make sure that the user has it.
        if (role && req.user.role !== role) {
            res.status(401);
            res.render('errors/401');
        }

        next();
    };
};

/**
 * A helper method to add the user to the response context so we don't have to manually do it.
 * @param req
 * @param res
 * @param next
 */
exports.injectUser = function (req, res, next) {
    if (req.isAuthenticated()) {
        res.locals.user = req.user;
        res.locals.path = req.path;
    }
    next();
};