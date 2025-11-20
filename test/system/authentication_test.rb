# frozen_string_literal: true

require "application_system_test_case"

class AuthenticationTest < ApplicationSystemTestCase
  setup do
    @admin = users(:admin)
    @user = users(:regular_user)
  end

  test "visiting login page shows sign in form" do
    visit new_user_session_path

    assert_selector "h2", text: /sign in/i
    assert_selector "input[name='user[email]']"
    assert_selector "input[name='user[password]']"
    assert_button "Log in"
  end

  test "admin can log in successfully" do
    visit new_user_session_path

    fill_in "Email", with: @admin.email
    fill_in "Password", with: "password123!"
    click_button "Log in"

    wait_for_page_load
    assert_current_path root_path
    assert_text "Signed in successfully"
  end

  test "invalid credentials show error" do
    visit new_user_session_path

    fill_in "Email", with: @admin.email
    fill_in "Password", with: "wrongpassword"
    click_button "Log in"

    wait_for_page_load
    assert_text "Invalid Email or password"
  end

  test "user can log out" do
    sign_in @admin
    visit root_path

    # Find and click logout (may be in dropdown or direct link)
    if page.has_link?("Sign out")
      click_link "Sign out"
    elsif page.has_button?("Sign out")
      click_button "Sign out"
    else
      # Try finding in navigation
      find("nav").click_link("Sign out") rescue nil
    end

    wait_for_page_load
    assert_text "Signed out successfully"
  end

  test "unauthenticated user is redirected to login" do
    visit dashboard_path

    assert_current_path new_user_session_path
  end
end
