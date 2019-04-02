import React from "react";
import styled from "@emotion/styled";
import {app, logoutUser } from "./../stitch";
import { Button } from "reactstrap";

const NavbarContainer = styled.div`
  height: 60px;
  padding: 10px 20px;
  line-height: 40px;
  display: flex;
  flex-direction: row-reverse;
`;

const LogoutButton = () => (
  <Button onClick={() => logoutUser(app.auth.user)}>Log Out</Button>
);

function Navbar() {
  return (
    <NavbarContainer>
      <LogoutButton />
    </NavbarContainer>
  );
}

export default Navbar;
